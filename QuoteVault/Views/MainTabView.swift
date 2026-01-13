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
            
            // Discover Tab (formerly Search)
            SearchView()
                .tabItem {
                    Label("Discover", systemImage: "safari")
                }
                .tag(1)
            
            // Library Tab (Favorites + Collections)
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(2)
            
            // Profile Tab (includes Settings)
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
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
