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
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    
    private let themeManager: ThemeManagerProtocol
    private let notificationScheduler: NotificationSchedulerProtocol
    private let quoteService: QuoteServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        themeManager: ThemeManagerProtocol = ThemeManager(),
        notificationScheduler: NotificationSchedulerProtocol = NotificationScheduler(),
        quoteService: QuoteServiceProtocol = QuoteService()
    ) {
        self.themeManager = themeManager
        self.notificationScheduler = notificationScheduler
        self.quoteService = quoteService
        
        // Load current theme settings
        themeManager.currentTheme
            .sink { [weak self] theme in
                self?.colorScheme = theme.colorScheme == "dark" ? .dark : (theme.colorScheme == "light" ? .light : nil)
                self?.accentColor = theme.accentColor
                self?.fontSize = theme.fontSize
            }
            .store(in: &cancellables)
        
        // Load notification settings
        Task {
            await loadNotificationSettings()
        }
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
    
    // MARK: - Notification Methods
    
    func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            // Request permission and schedule notification
            do {
                let granted = try await notificationScheduler.requestPermission()
                
                if granted {
                    // Get QOTD and schedule notification
                    let quote = try await quoteService.getQuoteOfTheDay()
                    let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
                    try await notificationScheduler.scheduleDaily(at: timeComponents, quote: quote)
                    
                    notificationsEnabled = true
                    saveNotificationSettings()
                } else {
                    // Permission denied
                    notificationsEnabled = false
                    errorMessage = "Notification permission denied. Please enable notifications in Settings."
                    showError = true
                }
            } catch {
                notificationsEnabled = false
                errorMessage = "Failed to enable notifications: \(error.localizedDescription)"
                showError = true
            }
        } else {
            // Disable notifications
            await notificationScheduler.cancelAllNotifications()
            notificationsEnabled = false
            saveNotificationSettings()
        }
    }
    
    func updateNotificationTime(_ time: Date) async {
        notificationTime = time
        
        // If notifications are enabled, update the scheduled time
        if notificationsEnabled {
            do {
                let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
                try await notificationScheduler.updateNotificationTime(timeComponents)
                saveNotificationSettings()
            } catch {
                errorMessage = "Failed to update notification time: \(error.localizedDescription)"
                showError = true
            }
        } else {
            saveNotificationSettings()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadNotificationSettings() async {
        // Load from UserDefaults
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: "notificationsEnabled")
        
        if let savedTime = defaults.object(forKey: "notificationTime") as? Date {
            notificationTime = savedTime
        } else {
            // Default to 9:00 AM
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            notificationTime = Calendar.current.date(from: components) ?? Date()
        }
        
        // Check actual authorization status
        let isAuthorized = await notificationScheduler.isAuthorized()
        notificationsEnabled = enabled && isAuthorized
    }
    
    private func saveNotificationSettings() {
        let defaults = UserDefaults.standard
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(notificationTime, forKey: "notificationTime")
    }
}
