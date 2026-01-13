//
//  MainTabView.swift
//  QuoteVault
//
//  Main tab navigation for the app
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Favorites Tab
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(1)
            
            // Collections Tab
            CollectionsListView()
                .tabItem {
                    Label("Collections", systemImage: "folder.fill")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .accentColor(themeManager.accentColor)
        .onChange(of: notificationDelegate.shouldNavigateToHome) { shouldNavigate in
            if shouldNavigate {
                // Navigate to Home tab when notification is tapped
                selectedTab = 0
                notificationDelegate.shouldNavigateToHome = false
            }
        }
    }
}

#Preview {
    MainTabView()
}
