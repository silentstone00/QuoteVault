//
//  AuthViewModel.swift
//  QuoteVault
//
//  View model for authentication flows
//

import Foundation
import Combine
import SwiftUI

/// View model managing authentication state and operations
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Form fields
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    
    // Validation states
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    
    // MARK: - Private Properties
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isSignUpFormValid: Bool {
        EmailValidator.isValid(email) &&
        PasswordValidator.isValid(password) &&
        password == confirmPassword &&
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isSignInFormValid: Bool {
        EmailValidator.isValid(email) &&
        !password.isEmpty
    }
    
    var isForgotPasswordFormValid: Bool {
        EmailValidator.isValid(email)
    }
    
    // MARK: - Initialization
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
        
        // Subscribe to auth state changes
        authService.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
        
        // Try to restore session on init
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Public Methods
    
    /// Sign up a new user
    func signUp() async {
        // Validate inputs
        guard validateSignUpForm() else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            
            // Update profile with display name
            try await authService.updateProfile(
                name: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarData: nil
            )
            
            currentUser = user
            isAuthenticated = true
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Sign in an existing user
    func signIn() async {
        // Validate inputs
        guard validateSignInForm() else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            
            currentUser = user
            isAuthenticated = true
            clearForm()
        } catch {
            errorMessage = "Invalid email or password"
        }
        
        isLoading = false
    }
    
    /// Sign out the current user
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            currentUser = nil
            isAuthenticated = false
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Send password reset email
    func resetPassword() async {
        // Validate email
        guard validateForgotPasswordForm() else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // Show success message
            errorMessage = "Password reset email sent. Please check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Restore session from stored credentials
    func restoreSession() async {
        isLoading = true
        
        do {
            if let user = try await authService.restoreSession() {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            // Silent fail - no session to restore
            print("Failed to restore session: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Update user profile
    func updateProfile(name: String?, avatarData: Data?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.updateProfile(name: name, avatarData: avatarData)
            // Refresh current user
            if let user = try await authService.restoreSession() {
                currentUser = user
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clear all form fields
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
    }
    
    // MARK: - Validation Methods
    
    private func validateSignUpForm() -> Bool {
        var isValid = true
        
        // Validate email
        let emailValidation = EmailValidator.validate(email)
        if !emailValidation.isValid {
            emailError = emailValidation.errorMessage
            isValid = false
        } else {
            emailError = nil
        }
        
        // Validate password
        let passwordValidation = PasswordValidator.validate(password)
        if !passwordValidation.isValid {
            passwordError = passwordValidation.errorMessage
            isValid = false
        } else {
            passwordError = nil
        }
        
        // Validate confirm password
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            isValid = false
        } else {
            confirmPasswordError = nil
        }
        
        // Validate display name
        if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Display name is required"
            isValid = false
        }
        
        return isValid
    }
    
    private func validateSignInForm() -> Bool {
        var isValid = true
        
        // Validate email
        let emailValidation = EmailValidator.validate(email)
        if !emailValidation.isValid {
            emailError = emailValidation.errorMessage
            isValid = false
        } else {
            emailError = nil
        }
        
        // Validate password is not empty
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        } else {
            passwordError = nil
        }
        
        return isValid
    }
    
    private func validateForgotPasswordForm() -> Bool {
        let emailValidation = EmailValidator.validate(email)
        if !emailValidation.isValid {
            emailError = emailValidation.errorMessage
            return false
        } else {
            emailError = nil
            return true
        }
    }
}
