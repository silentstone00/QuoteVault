//
//  ThemeManager.swift
//  QuoteVault
//
//  Service for managing app theme and appearance
//

import Foundation
import SwiftUI
import Combine

/// Accent color options
enum AccentColorOption: String, CaseIterable, Codable {
    case blue
    case purple
    case orange
    case green
    case pink
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .green: return .green
        case .pink: return .pink
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
}

/// Font size options
enum FontSizeOption: String, CaseIterable, Codable {
    case small
    case medium
    case large
    case extraLarge
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}

/// App theme model
struct AppTheme: Codable {
    var colorScheme: String? // "light", "dark", or nil for system
    var accentColor: AccentColorOption
    var fontSize: FontSizeOption
    
    static let `default` = AppTheme(
        colorScheme: nil,
        accentColor: .blue,
        fontSize: .medium
    )
}

/// Protocol defining theme management operations
protocol ThemeManagerProtocol {
    var currentTheme: AnyPublisher<AppTheme, Never> { get }
    var colorScheme: ColorScheme? { get }
    var accentColor: Color { get }
    var quoteFontSize: CGFloat { get }
    
    func setColorScheme(_ scheme: ColorScheme?)
    func setAccentColor(_ color: AccentColorOption)
    func setFontSize(_ size: FontSizeOption)
    func syncToCloud() async throws
}

/// Theme manager implementation
class ThemeManager: ThemeManagerProtocol, ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var theme: AppTheme
    
    // MARK: - Private Properties
    
    private let localStorage: UserDefaults
    private let authService: AuthServiceProtocol
    private let themeKey = "app_theme"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Properties
    
    var currentTheme: AnyPublisher<AppTheme, Never> {
        $theme.eraseToAnyPublisher()
    }
    
    var colorScheme: ColorScheme? {
        guard let schemeString = theme.colorScheme else {
            return nil // System default
        }
        return schemeString == "dark" ? .dark : .light
    }
    
    var accentColor: Color {
        theme.accentColor.color
    }
    
    var quoteFontSize: CGFloat {
        theme.fontSize.fontSize
    }
    
    // MARK: - Initialization
    
    init(
        localStorage: UserDefaults = .standard,
        authService: AuthServiceProtocol = AuthService()
    ) {
        self.localStorage = localStorage
        self.authService = authService
        
        // Load saved theme or use default
        if let data = localStorage.data(forKey: themeKey),
           let savedTheme = try? JSONDecoder().decode(AppTheme.self, from: data) {
            self.theme = savedTheme
        } else {
            self.theme = .default
        }
        
        // Listen for auth state changes to sync theme
        authService.currentUser
            .sink { [weak self] user in
                if user != nil {
                    Task {
                        try? await self?.syncToCloud()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func setColorScheme(_ scheme: ColorScheme?) {
        if let scheme = scheme {
            theme.colorScheme = scheme == .dark ? "dark" : "light"
        } else {
            theme.colorScheme = nil
        }
        saveTheme()
        objectWillChange.send()
    }
    
    func setAccentColor(_ color: AccentColorOption) {
        theme.accentColor = color
        saveTheme()
        objectWillChange.send()
    }
    
    func setFontSize(_ size: FontSizeOption) {
        theme.fontSize = size
        saveTheme()
        objectWillChange.send()
    }
    
    func syncToCloud() async throws {
        // For now, just save locally
        // In a full implementation, this would sync through AuthService
        // to update user preferences in Supabase
        saveTheme()
    }
    
    // MARK: - Private Methods
    
    private func saveTheme() {
        if let encoded = try? JSONEncoder().encode(theme) {
            localStorage.set(encoded, forKey: themeKey)
        }
    }
}
