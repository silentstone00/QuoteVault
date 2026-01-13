//
//  EmailValidator.swift
//  QuoteVault
//
//  Email validation using regex pattern
//

import Foundation

/// Validator for email addresses
struct EmailValidator {
    /// Email validation regex pattern
    /// Matches standard email format: username@domain.extension
    private static let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    
    /// Validates an email address format
    /// - Parameter email: The email address to validate
    /// - Returns: True if the email format is valid, false otherwise
    static func isValid(_ email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            return false
        }
        
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: trimmedEmail)
    }
    
    /// Validates an email and returns a validation result
    /// - Parameter email: The email address to validate
    /// - Returns: ValidationResult with success or error message
    static func validate(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            return .failure("Email address is required")
        }
        
        if !isValid(trimmedEmail) {
            return .failure("Please enter a valid email address")
        }
        
        return .success
    }
}

/// Validation result type
enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}
