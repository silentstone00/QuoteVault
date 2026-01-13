//
//  QuoteVaultApp.swift
//  QuoteVault
//
//  Main app entry point with auth state routing
//

import SwiftUI

@main
struct QuoteVaultApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Configure app appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    // Show main app
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    // Show login
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .onAppear {
                // Restore session on app launch
                Task {
                    await authViewModel.restoreSession()
                }
            }
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
