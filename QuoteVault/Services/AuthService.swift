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
        // Sign up with Supabase Auth
        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        guard let session = authResponse.session else {
            throw AuthError.signUpFailed("No session returned after sign up")
        }
        
        // Fetch the user profile (created automatically by trigger)
        let user = try await fetchUserProfile(userId: session.user.id)
        
        // Update local state
        userSubject.send(user)
        
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // Sign in with Supabase Auth
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        // Fetch the user profile
        let user = try await fetchUserProfile(userId: session.user.id)
        
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
        guard let userId = userSubject.value?.id else {
            throw AuthError.notAuthenticated
        }
        
        var avatarUrl: String?
        
        // Upload avatar if provided
        if let avatarData = avatarData {
            let fileName = "\(userId.uuidString).jpg"
            let path = "avatars/\(fileName)"
            
            try await supabase.storage
                .from("avatars")
                .upload(path: path, file: avatarData, options: .init(upsert: true))
            
            // Get public URL
            avatarUrl = try supabase.storage
                .from("avatars")
                .getPublicURL(path: path)
                .absoluteString
        }
        
        // Update profile in database
        var updates: [String: Any] = [:]
        if let name = name {
            updates["display_name"] = name
        }
        if let avatarUrl = avatarUrl {
            updates["avatar_url"] = avatarUrl
        }
        updates["updated_at"] = ISO8601DateFormatter().string(from: Date())
        
        try await supabase.database
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()
        
        // Refresh user profile
        let updatedUser = try await fetchUserProfile(userId: userId)
        userSubject.send(updatedUser)
    }
    
    func restoreSession() async throws -> User? {
        // Try to get current session
        guard let session = try? await supabase.auth.session else {
            return nil
        }
        
        // Fetch user profile
        let user = try await fetchUserProfile(userId: session.user.id)
        
        // Update local state
        userSubject.send(user)
        
        return user
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() async {
        // Listen for auth state changes
        for await state in supabase.auth.authStateChanges {
            switch state {
            case .signedIn(let session):
                if let user = try? await fetchUserProfile(userId: session.user.id) {
                    userSubject.send(user)
                }
            case .signedOut:
                userSubject.send(nil)
            default:
                break
            }
        }
    }
    
    private func fetchUserProfile(userId: UUID) async throws -> User {
        let response: [User] = try await supabase.database
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        
        guard let user = response.first else {
            throw AuthError.profileNotFound
        }
        
        return user
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
