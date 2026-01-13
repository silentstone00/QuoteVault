//
//  SettingsViewModel.swift
//  QuoteVault
//
//  ViewModel for managing app settings
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var colorScheme: ColorScheme?
    @Published var accentColor: AccentColorOption = .blue
    @Published var fontSize: FontSizeOption = .medium
    @Published var notificationsEnabled = false
    @Published var notificationTime = Date()
    
    // MARK: - Private Properties
    
    private let themeManager: ThemeManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(themeManager: ThemeManagerProtocol = ThemeManager()) {
        self.themeManager = themeManager
        
        // Load current theme settings
        themeManager.currentTheme
            .sink { [weak self] theme in
                self?.colorScheme = theme.colorScheme == "dark" ? .dark : (theme.colorScheme == "light" ? .light : nil)
                self?.accentColor = theme.accentColor
                self?.fontSize = theme.fontSize
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func updateColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        themeManager.setColorScheme(scheme)
    }
    
    func updateAccentColor(_ color: AccentColorOption) {
        accentColor = color
        themeManager.setAccentColor(color)
    }
    
    func updateFontSize(_ size: FontSizeOption) {
        fontSize = size
        themeManager.setFontSize(size)
    }
    
    func syncSettings() async {
        do {
            try await themeManager.syncToCloud()
        } catch {
            print("Failed to sync settings: \(error)")
        }
    }
}
