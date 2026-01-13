//
//  ThemeManagerPropertyTests.swift
//  QuoteVaultTests
//
//  Property-based tests for ThemeManager
//

import XCTest
import SwiftCheck
@testable import QuoteVault

/// Feature: quotevault-app
/// Property 14: Theme Settings Round-Trip
/// For any theme setting (color scheme, accent color, font size),
/// setting a value and then reading it SHALL return the same value.
/// Validates: Requirements 9.1, 9.2, 9.4, 9.5, 9.6
final class ThemeManagerPropertyTests: XCTestCase {
    
    var themeManager: ThemeManager!
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Use a test suite name to avoid conflicts
        testDefaults = UserDefaults(suiteName: "ThemeManagerTests")!
        testDefaults.removePersistentDomain(forName: "ThemeManagerTests")
        
        // Create mock auth service
        let mockAuthService = MockAuthService()
        themeManager = ThemeManager(localStorage: testDefaults, authService: mockAuthService)
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "ThemeManagerTests")
        testDefaults = nil
        themeManager = nil
        super.tearDown()
    }
    
    // MARK: - Property 14: Theme Settings Round-Trip
    
    func testProperty14_ColorSchemeRoundTrip() {
        property("Setting and reading color scheme returns same value") <- forAll { (useDark: Bool) in
            let scheme: ColorScheme? = useDark ? .dark : .light
            
            self.themeManager.setColorScheme(scheme)
            let retrieved = self.themeManager.colorScheme
            
            return retrieved == scheme
        }
    }
    
    func testProperty14_ColorSchemeSystemDefault() {
        property("Setting nil color scheme returns nil (system default)") <- forAll { (_: Int) in
            self.themeManager.setColorScheme(nil)
            let retrieved = self.themeManager.colorScheme
            
            return retrieved == nil
        }
    }
    
    func testProperty14_AccentColorRoundTrip() {
        property("Setting and reading accent color returns same value") <- forAll { (index: Int) in
            let colors = AccentColorOption.allCases
            let color = colors[abs(index) % colors.count]
            
            self.themeManager.setAccentColor(color)
            
            // Wait for published value to update
            let expectation = self.expectation(description: "Theme updated")
            var retrievedColor: AccentColorOption?
            
            let cancellable = self.themeManager.currentTheme.sink { theme in
                retrievedColor = theme.accentColor
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 1.0)
            cancellable.cancel()
            
            return retrievedColor == color
        }
    }
    
    func testProperty14_FontSizeRoundTrip() {
        property("Setting and reading font size returns same value") <- forAll { (index: Int) in
            let sizes = FontSizeOption.allCases
            let size = sizes[abs(index) % sizes.count]
            
            self.themeManager.setFontSize(size)
            
            // Wait for published value to update
            let expectation = self.expectation(description: "Theme updated")
            var retrievedSize: FontSizeOption?
            
            let cancellable = self.themeManager.currentTheme.sink { theme in
                retrievedSize = theme.fontSize
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 1.0)
            cancellable.cancel()
            
            return retrievedSize == size
        }
    }
    
    func testProperty14_FontSizeValueMapping() {
        property("Font size option maps to correct CGFloat value") <- forAll { (index: Int) in
            let sizes = FontSizeOption.allCases
            let size = sizes[abs(index) % sizes.count]
            
            self.themeManager.setFontSize(size)
            let fontSize = self.themeManager.quoteFontSize
            
            let expectedSize: CGFloat
            switch size {
            case .small: expectedSize = 14
            case .medium: expectedSize = 16
            case .large: expectedSize = 18
            case .extraLarge: expectedSize = 20
            }
            
            return fontSize == expectedSize
        }
    }
    
    func testProperty14_AccentColorValueMapping() {
        property("Accent color option maps to correct Color") <- forAll { (index: Int) in
            let colors = AccentColorOption.allCases
            let colorOption = colors[abs(index) % colors.count]
            
            self.themeManager.setAccentColor(colorOption)
            
            // Verify the color is accessible
            let color = self.themeManager.accentColor
            
            // We can't directly compare SwiftUI Colors, but we can verify it's not nil
            // and matches the expected color option
            return color == colorOption.color
        }
    }
    
    func testProperty14_ThemePersistence() {
        property("Theme settings persist across ThemeManager instances") <- forAll { (index: Int) in
            let colors = AccentColorOption.allCases
            let sizes = FontSizeOption.allCases
            
            let color = colors[abs(index) % colors.count]
            let size = sizes[abs(index) % sizes.count]
            
            // Set values in first instance
            self.themeManager.setAccentColor(color)
            self.themeManager.setFontSize(size)
            
            // Create new instance with same UserDefaults
            let mockAuthService = MockAuthService()
            let newManager = ThemeManager(localStorage: self.testDefaults, authService: mockAuthService)
            
            // Wait for theme to load
            let expectation = self.expectation(description: "Theme loaded")
            var loadedTheme: AppTheme?
            
            let cancellable = newManager.currentTheme.sink { theme in
                loadedTheme = theme
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 1.0)
            cancellable.cancel()
            
            return loadedTheme?.accentColor == color && loadedTheme?.fontSize == size
        }
    }
}

// MARK: - Mock Auth Service

class MockAuthService: AuthServiceProtocol {
    var currentUser: AnyPublisher<User?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
    
    var isAuthenticated: Bool {
        false
    }
    
    func signUp(email: String, password: String) async throws -> User {
        throw NSError(domain: "Mock", code: 0)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        throw NSError(domain: "Mock", code: 0)
    }
    
    func signOut() async throws {
        // No-op
    }
    
    func resetPassword(email: String) async throws {
        // No-op
    }
    
    func updateProfile(name: String?, avatarData: Data?) async throws {
        // No-op
    }
    
    func restoreSession() async throws -> User? {
        return nil
    }
}
