//
//  CollectionDetailView.swift
//  QuoteVault
//
//  View showing quotes in a specific collection
//

import SwiftUI

struct CollectionDetailView: View {
    let collection: QuoteCollection
    @ObservedObject private var viewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.selectedCollectionQuotes.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No Quotes Yet",
                    message: "Add quotes to this collection from your favorites"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.selectedCollectionQuotes) { quote in
                            CollectionQuoteCard(
                                quote: quote,
                                onRemove: {
                                    Task {
                                        await viewModel.removeFromCollection(
                                            quoteId: quote.id,
                                            collectionId: collection.id
                                        )
                                    }
                                }
                            )
                            .environmentObject(themeManager)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
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
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        Label("Delete Collection", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Collection", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteCollection(id: collection.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(collection.name)'? This action cannot be undone.")
        }
        .task {
            await viewModel.loadCollectionQuotes(collectionId: collection.id)
        }
    }
}

// MARK: - Collection Quote Card

struct CollectionQuoteCard: View {
    let quote: Quote
    let onRemove: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote Text
            Text(quote.text)
                .font(.system(size: themeManager.quoteFontSize))
                .foregroundColor(.primary)
            
            // Author and Category
            HStack {
                Text("— \(quote.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                CategoryBadge(category: quote.category)
            }
            
            // Remove Button
            HStack {
                Spacer()
                Button(action: onRemove) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.minus")
                        Text("Remove")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    NavigationView {
        CollectionDetailView(collection: QuoteCollection(
            id: UUID(),
            name: "My Favorites",
            userId: UUID(),
            createdAt: Date()
        ))
    }
}
