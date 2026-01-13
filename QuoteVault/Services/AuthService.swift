//
//  AuthService.swift
//  QuoteVault
//
//  Authentication service for user sign up, sign in, and session management
//

import Foundation
import Supabase
import Combine

/// Protocol defining authentication service operations
protocol AuthServiceProtocol {
    /// Publisher that emits the current user state
    var currentUser: AnyPublisher<User?, Never> { get }
    
    /// Whether a user is currently authenticated
    var isAuthenticated: Bool { get }
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The created user
    /// - Throws: Authentication errors
    func signUp(email: String, password: String) async throws -> User
    
    /// Sign in an existing user
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated user
    /// - Throws: Authentication errors
    func signIn(email: String, password: String) async throws -> User
    
    /// Sign out the current user
    /// - Throws: Sign out errors
    func signOut() async throws
    
    /// Send password reset email
    /// - Parameter email: User's email address
    /// - Throws: Password reset errors
    func resetPassword(email: String) async throws
    
    /// Update user profile information
    /// - Parameters:
    ///   - name: Optional display name
    ///   - avatarData: Optional avatar image data
    /// - Throws: Profile update errors
    func updateProfile(name: String?, avatarData: Data?) async throws
    
    /// Restore session from stored credentials
    /// - Returns: The restored user, or nil if no valid session
    /// - Throws: Session restoration errors
    func restoreSession() async throws -> User?
}

/// Authentication service implementation using Supabase
class AuthService: AuthServiceProtocol {
    // MARK: - Properties
    
    private let supabase: SupabaseClient
    private let userSubject = CurrentValueSubject<User?, Never>(nil)
    
    var currentUser: AnyPublisher<User?, Never> {
        userSubject.eraseToAnyPublisher()
    }
    
    var isAuthenticated: Bool {
        userSubject.value != nil
    }
    
    // MARK: - Initialization
    
    init(supabase: SupabaseClient = SupabaseConfig.shared) {
        self.supabase = supabase
        
        // Listen for auth state changes
        Task {
            await setupAuthStateListener()
        }
    }
    
    // MARK: - Public Methods
    
    func signUp(email: String, password: String) async throws -> User {
        print("🔵 Starting signup for: \(email)")
        
        // Sign up with Supabase Auth
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            print("🔵 Auth signup successful")
            print("🔵 Session: \(authResponse.session != nil ? "exists" : "nil")")
            
            // If email confirmation is required, session will be nil
            if authResponse.session == nil {
                print("⚠️ No session - email confirmation may be required")
                // For now, throw a user-friendly error
                throw AuthError.signUpFailed("Please check your email to confirm your account")
            }
            
            guard let session = authResponse.session else {
                print("🔴 No session returned after signup")
                throw AuthError.signUpFailed("No session returned after sign up")
            }
            
            print("🔵 Session obtained, user ID: \(session.user.id)")
            print("🔵 User email: \(session.user.email ?? "no email")")
            print("🔵 Waiting 500ms for trigger...")
            
            // Wait a moment for the trigger to create the profile
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            print("🔵 Attempting to fetch profile...")
            
            // Try to fetch the user profile (created by trigger)
            do {
                let user = try await fetchUserProfile(userId: session.user.id, email: session.user.email ?? email)
                print("✅ Profile fetched successfully")
                userSubject.send(user)
                return user
            } catch {
                // If profile doesn't exist, create it manually
                print("⚠️ Profile not found, error: \(error)")
                print("🔵 Creating profile manually...")
                
                do {
                    let user = try await createUserProfile(
                        userId: session.user.id,
                        email: session.user.email ?? email
                    )
                    print("✅ Profile created manually")
                    userSubject.send(user)
                    return user
                } catch {
                    print("🔴 Failed to create profile manually: \(error)")
                    throw AuthError.signUpFailed("Database error saving new user: \(error.localizedDescription)")
                }
            }
        } catch let error as AuthError {
            print("🔴 Auth error: \(error)")
            throw error
        } catch {
            print("🔴 Signup failed with error: \(error)")
            throw AuthError.signUpFailed("Signup failed: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // Sign in with Supabase Auth
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        // Fetch the user profile
        let user = try await fetchUserProfile(userId: session.user.id, email: session.user.email ?? email)
        
        // Update local state
        userSubject.send(user)
        
        return user
    }
    
    func signOut() async throws {
        // Sign out from Supabase
        try await supabase.auth.signOut()
        
        // Clear local state
        userSubject.send(nil)
    }
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    func updateProfile(name: String?, avatarData: Data?) async throws {
        guard let currentUser = userSubject.value else {
            throw AuthError.notAuthenticated
        }
        
        let userId = currentUser.id
        var avatarUrl: String?
        
        // Upload avatar if provided
        if let avatarData = avatarData {
            let fileName = "\(userId.uuidString).jpg"
            let avatarPath = "avatars/\(fileName)"
            
            try await supabase.storage
                .from("avatars")
                .upload(avatarPath, data: avatarData, options: .init(upsert: true))
            
            // Get public URL
            avatarUrl = try supabase.storage
                .from("avatars")
                .getPublicURL(path: avatarPath)
                .absoluteString
        }
        
        // Update profile in database
        struct ProfileUpdate: Encodable {
            let display_name: String?
            let avatar_url: String?
            let updated_at: String
        }
        
        let update = ProfileUpdate(
            display_name: name,
            avatar_url: avatarUrl,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
        
        // Refresh user profile
        let updatedUser = try await fetchUserProfile(userId: userId, email: currentUser.email)
        userSubject.send(updatedUser)
    }
    
    func restoreSession() async throws -> User? {
        // Try to get current session - don't fail if offline
        do {
            let session = try await supabase.auth.session
            
            // Fetch user profile
            let user = try await fetchUserProfile(userId: session.user.id, email: session.user.email ?? "")
            
            // Update local state
            userSubject.send(user)
            
            return user
        } catch {
            // If offline or network error, return nil instead of throwing
            print("Session restoration failed (possibly offline): \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() async {
        // Listen for auth state changes
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .signedIn:
                if let session = session,
                   let user = try? await fetchUserProfile(userId: session.user.id, email: session.user.email ?? "") {
                    userSubject.send(user)
                }
            case .signedOut:
                userSubject.send(nil)
            default:
                break
            }
        }
    }
    
    private func fetchUserProfile(userId: UUID, email: String) async throws -> User {
        // Define a struct that matches what we get from the database
        struct ProfileResponse: Codable {
            let id: UUID
            let display_name: String?
            let avatar_url: String?
            let preferences: UserPreferences?
            let created_at: Date
        }
        
        let response: [ProfileResponse] = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        
        guard let profile = response.first else {
            throw AuthError.profileNotFound
        }
        
        // Construct User with email from auth
        return User(
            id: profile.id,
            email: email,
            displayName: profile.display_name,
            avatarUrl: profile.avatar_url,
            preferences: profile.preferences,
            createdAt: profile.created_at
        )
    }
    
    private func createUserProfile(userId: UUID, email: String) async throws -> User {
        print("🔵 Creating profile for user: \(userId)")
        
        // Extract display name from email
        let displayName = email.components(separatedBy: "@").first ?? "User"
        print("🔵 Display name: \(displayName)")
        
        // Create profile manually
        struct ProfileInsert: Encodable {
            let id: String
            let display_name: String
        }
        
        let insert = ProfileInsert(
            id: userId.uuidString,
            display_name: displayName
        )
        
        print("🔵 Inserting profile into database...")
        
        do {
            try await supabase
                .from("profiles")
                .insert(insert)
                .execute()
            
            print("✅ Profile inserted successfully")
        } catch {
            print("🔴 Profile insert failed: \(error)")
            throw error
        }
        
        print("🔵 Fetching created profile...")
        
        // Fetch the created profile
        return try await fetchUserProfile(userId: userId, email: email)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case signUpFailed(String)
    case notAuthenticated
    case profileNotFound
    case invalidCredentials
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .notAuthenticated:
            return "User is not authenticated"
        case .profileNotFound:
            return "User profile not found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error occurred"
        }
    }
}
