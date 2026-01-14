//
//  QuoteVaultApp.swift
//  QuoteVault
//
//  Main app entry point with auth state routing
//

import SwiftUI
import UserNotifications
import Combine

@main
struct QuoteVaultApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var notificationDelegate = NotificationDelegate()
    
    init() {
        // Configure app appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoading {
                    // Show loading during session restoration
                    ZStack {
                        Color.customBackground
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if authViewModel.isAuthenticated {
                    // Show main app
                    MainTabView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                        .environmentObject(notificationDelegate)
                } else {
                    // Show login
                    LoginView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                }
            }
            .preferredColorScheme(themeManager.colorScheme)
            .accentColor(themeManager.accentColor)
            .onOpenURL { url in
                // Handle deep links from widget
                if url.scheme == "quotevault" && url.host == "qotd" {
                    // Navigate to home tab to show QOTD
                    notificationDelegate.shouldNavigateToHome = true
                }
            }
            .onAppear {
                // Restore session on app launch
                Task {
                    await authViewModel.restoreSession()
                    
                    // Update widget if needed
                    await WidgetUpdateService.updateIfNeeded(quoteService: QuoteService())
                }
                
                // Set notification delegate
                UNUserNotificationCenter.current().delegate = notificationDelegate
            }
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance with reduced spacing
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Reduce large title top padding
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Reduce layout margins to minimize spacing
        UINavigationBar.appearance().layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var selectedQuoteId: UUID?
    @Published var shouldNavigateToHome = false
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract quote ID from notification
        if let quoteIdString = userInfo["quoteId"] as? String,
           let quoteId = UUID(uuidString: quoteIdString) {
            DispatchQueue.main.async {
                self.selectedQuoteId = quoteId
                self.shouldNavigateToHome = true
            }
        }
        
        completionHandler()
    }
}
