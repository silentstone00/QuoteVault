//
//  CollectionsListView.swift
//  QuoteVault
//
//  View showing all user collections
//

import SwiftUI

struct CollectionsListView: View {
    @StateObject private var viewModel = CollectionViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.collections.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Collections Yet",
                        message: "Create a collection to organize your favorite quotes"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.collections) { collection in
                                NavigationLink(destination: CollectionDetailView(collection: collection)) {
                                    CollectionCard(collection: collection)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.syncFromCloud()
                    }
                }
                
                // Error Banner
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        ErrorBanner(message: error) {
                            viewModel.clearError()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showCreateCollection = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateCollection) {
                CreateCollectionSheet { name in
                    Task {
                        await viewModel.createCollection(name: name)
                    }
                }
            }
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: QuoteCollection
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            // Collection Info
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(collection.quoteCount ?? 0) quotes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    CollectionsListView()
}
