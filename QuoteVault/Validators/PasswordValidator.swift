//
//  PasswordValidator.swift
//  QuoteVault
//
//  Password validation with length and complexity rules
//

import Foundation

/// Validator for password strength and requirements
struct PasswordValidator {
    /// Minimum password length requirement
    static let minimumLength = 8
    
    /// Validates a password meets minimum requirements
    /// - Parameter password: The password to validate
    /// - Returns: True if the password meets requirements, false otherwise
    static func isValid(_ password: String) -> Bool {
        return password.count >= minimumLength
    }
    
    /// Validates a password and returns a detailed validation result
    /// - Parameter password: The password to validate
    /// - Returns: ValidationResult with success or error message
    static func validate(_ password: String) -> ValidationResult {
        if password.isEmpty {
            return .failure("Password is required")
        }
        
        if password.count < minimumLength {
            return .failure("Password must be at least \(minimumLength) characters long")
        }
        
        return .success
    }
    
    /// Gets password strength level
    /// - Parameter password: The password to evaluate
    /// - Returns: PasswordStrength level
    static func strength(_ password: String) -> PasswordStrength {
        if password.count < minimumLength {
            return .weak
        }
        
        var score = 0
        
        // Length bonus
        if password.count >= 12 {
            score += 1
        }
        
        // Contains uppercase
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            score += 1
        }
        
        // Contains lowercase
        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            score += 1
        }
        
        // Contains number
        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            score += 1
        }
        
        // Contains special character
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil {
            score += 1
        }
        
        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        default:
            return .strong
        }
    }
    
    /// Password strength levels
    enum PasswordStrength {
        case weak
        case medium
        case strong
        
        var description: String {
            switch self {
            case .weak:
                return "Weak"
            case .medium:
                return "Medium"
            case .strong:
                return "Strong"
            }
        }
        
        var color: String {
            switch self {
            case .weak:
                return "red"
            case .medium:
                return "orange"
            case .strong:
                return "green"
            }
        }
    }
}
