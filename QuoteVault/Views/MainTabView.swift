//
//  MainTabView.swift
//  QuoteVault
//
//  Main tab navigation for the app
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Favorites Tab
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            
            // Collections Tab
            CollectionsListView()
                .tabItem {
                    Label("Collections", systemImage: "folder.fill")
                }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}
