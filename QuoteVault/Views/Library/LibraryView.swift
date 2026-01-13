//
//  LibraryView.swift
//  QuoteVault
//
//  Combined view for Favorites and Collections
//

import SwiftUI

struct LibraryView: View {
    @State private var selectedSegment = 0
    @ObservedObject private var collectionViewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Library Section", selection: $selectedSegment) {
                    Text("Favorites").tag(0)
                    Text("Collections").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedSegment) {
                    FavoritesView()
                        .tag(0)
                    
                    CollectionsListView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedSegment == 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
    }
}

#Preview {
    LibraryView()
        .environmentObject(ThemeManager())
}
