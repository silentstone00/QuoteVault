//
//  ValidatorPropertyTests.swift
//  QuoteVaultTests
//
//  Property-based tests for email and password validators
//

import XCTest
import SwiftCheck
@testable import QuoteVault

/// Feature: quotevault-app, Property 1 & 2: Email and Password Validation
/// Validates: Requirements 1.2, 1.3
final class ValidatorPropertyTests: XCTestCase {
    
    // MARK: - Property 1: Email Validation Rejects Invalid Formats
    
    /// Property 1: Email Validation Rejects Invalid Formats
    /// For any string that does not match a valid email format (missing @, missing domain,
    /// invalid characters), the email validator SHALL return false and prevent sign-up submission.
    func testEmailValidationRejectsInvalidFormats() {
        property("Email validator rejects strings without @ symbol") <- forAll { (localPart: String, domain: String) in
            // Generate invalid emails without @ symbol
            let invalidEmail = localPart + domain
            
            // If the string happens to contain @, skip this test case
            guard !invalidEmail.contains("@") else {
                return true
            }
            
            // Property: emails without @ should be invalid
            return !EmailValidator.isValid(invalidEmail)
        }
        
        property("Email validator rejects strings with missing domain") <- forAll { (localPart: String) in
            // Generate emails with @ but no domain
            let invalidEmail = localPart + "@"
            
            // Property: emails with @ but no domain should be invalid
            return !EmailValidator.isValid(invalidEmail)
        }
        
        property("Email validator rejects strings with missing local part") <- forAll { (domain: String) in
            // Generate emails with no local part
            let invalidEmail = "@" + domain
            
            // Property: emails with no local part should be invalid
            return !EmailValidator.isValid(invalidEmail)
        }
        
        property("Email validator rejects empty strings") <- forAll { (whitespace: String) in
            // Generate strings with only whitespace
            let emptyEmail = String(repeating: " ", count: abs(whitespace.count % 10))
            
            // Property: empty or whitespace-only strings should be invalid
            return !EmailValidator.isValid(emptyEmail)
        }
    }
    
    /// Additional test: Valid email formats are accepted
    func testEmailValidationAcceptsValidFormats() {
        property("Email validator accepts valid email formats") <- forAll(arbitraryValidEmail()) { (email: String) in
            // Property: properly formatted emails should be valid
            return EmailValidator.isValid(email)
        }
    }
    
    // MARK: - Property 2: Password Validation Rejects Short Passwords
    
    /// Property 2: Password Validation Rejects Short Passwords
    /// For any string with length less than 8 characters, the password validator
    /// SHALL return false and display password requirements.
    func testPasswordValidationRejectsShortPasswords() {
        property("Password validator rejects passwords shorter than 8 characters") <- forAll { (shortString: String) in
            // Generate passwords with length 0-7
            let length = abs(shortString.count % 8) // 0 to 7
            let shortPassword = String(shortString.prefix(length))
            
            // Property: passwords shorter than 8 characters should be invalid
            let isValid = PasswordValidator.isValid(shortPassword)
            let validationResult = PasswordValidator.validate(shortPassword)
            
            return !isValid && !validationResult.isValid
        }
        
        property("Password validator provides error message for short passwords") <- forAll { (shortString: String) in
            // Generate passwords with length 0-7
            let length = abs(shortString.count % 8)
            let shortPassword = String(shortString.prefix(length))
            
            // Property: validation should return failure with error message
            let validationResult = PasswordValidator.validate(shortPassword)
            
            if case .failure(let message) = validationResult {
                return !message.isEmpty
            }
            return false
        }
    }
    
    /// Additional test: Valid passwords are accepted
    func testPasswordValidationAcceptsValidPasswords() {
        property("Password validator accepts passwords with 8+ characters") <- forAll(arbitraryValidPassword()) { (password: String) in
            // Property: passwords with 8 or more characters should be valid
            return PasswordValidator.isValid(password) && password.count >= 8
        }
    }
    
    /// Test password strength calculation
    func testPasswordStrengthCalculation() {
        property("Weak passwords have strength level weak") <- forAll { (chars: String) in
            // Generate short passwords (less than 8 chars)
            let weakPassword = String(chars.prefix(7))
            
            // Property: short passwords should be weak
            let strength = PasswordValidator.strength(weakPassword)
            return strength == .weak
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmailValidatorEdgeCases() {
        // Test empty string
        XCTAssertFalse(EmailValidator.isValid(""))
        
        // Test whitespace only
        XCTAssertFalse(EmailValidator.isValid("   "))
        
        // Test missing @
        XCTAssertFalse(EmailValidator.isValid("testexample.com"))
        
        // Test missing domain
        XCTAssertFalse(EmailValidator.isValid("test@"))
        
        // Test missing local part
        XCTAssertFalse(EmailValidator.isValid("@example.com"))
        
        // Test valid email
        XCTAssertTrue(EmailValidator.isValid("test@example.com"))
    }
    
    func testPasswordValidatorEdgeCases() {
        // Test empty string
        XCTAssertFalse(PasswordValidator.isValid(""))
        
        // Test exactly 7 characters (boundary)
        XCTAssertFalse(PasswordValidator.isValid("1234567"))
        
        // Test exactly 8 characters (boundary)
        XCTAssertTrue(PasswordValidator.isValid("12345678"))
        
        // Test 9 characters
        XCTAssertTrue(PasswordValidator.isValid("123456789"))
    }
}

// MARK: - Generators

/// Generate valid email addresses for testing
func arbitraryValidEmail() -> Gen<String> {
    return Gen<String>.fromElements(of: [
        "test@example.com",
        "user@domain.org",
        "admin@company.net",
        "john.doe@email.com",
        "jane_smith@test.co.uk",
        "contact+tag@service.io"
    ])
}

/// Generate valid passwords for testing
func arbitraryValidPassword() -> Gen<String> {
    return Gen<String>.fromElements(of: [
        "password123",
        "SecurePass1",
        "MyP@ssw0rd",
        "LongPassword123",
        "Test1234",
        "ValidPass99"
    ])
}
