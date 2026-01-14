//
//  LibraryView.swift
//  QuoteVault
//
//  Combined view for Favorites and Collections
//

import SwiftUI

struct LibraryView: View {
    @State private var selectedSegment = 0
    @State private var isFavoritesSelectionMode = false
    @ObservedObject private var collectionViewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.customBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Pill Toggle
                    HStack(spacing: 0) {
                        // Favorites Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSegment = 0
                            }
                        }) {
                            Text("Favorites")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedSegment == 0 ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedSegment == 0 ? themeManager.accentColor : Color.clear
                                )
                                .cornerRadius(20)
                        }
                        
                        // Collections Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSegment = 1
                            }
                        }) {
                            Text("Collections")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedSegment == 1 ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedSegment == 1 ? themeManager.accentColor : Color.clear
                                )
                                .cornerRadius(20)
                        }
                    }
                    .padding(4)
                    .background(Color.customCard)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    // Content
                    TabView(selection: $selectedSegment) {
                        FavoritesView(isSelectionMode: $isFavoritesSelectionMode)
                            .tag(0)
                        
                        CollectionsListView()
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.customBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedSegment == 0 {
                        // Favorites: Show Select button
                        Button(isFavoritesSelectionMode ? "Done" : "Select") {
                            withAnimation {
                                isFavoritesSelectionMode.toggle()
                            }
                        }
                    } else {
                        // Collections: Show Plus button
                        Button(action: {
                            collectionViewModel.showCreateCollection = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $collectionViewModel.showCreateCollection) {
                CreateCollectionSheet { name in
                    Task {
                        await collectionViewModel.createCollection(name: name)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    LibraryView()
        .environmentObject(ThemeManager())
}
