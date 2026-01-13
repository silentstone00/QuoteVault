//
//  FavoritesView.swift
//  QuoteVault
//
//  View showing all favorited quotes
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject private var viewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.favorites.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No Favorites Yet",
                    message: "Tap the heart icon on any quote to add it to your favorites"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.favorites) { quote in
                            FavoriteQuoteCard(
                                quote: quote,
                                onUnfavorite: {
                                    Task {
                                        await viewModel.toggleFavorite(quote: quote)
                                    }
                                },
                                onAddToCollection: {
                                    viewModel.showAddToCollectionSheet(for: quote)
                                }
                            )
                            .environmentObject(themeManager)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
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
        .sheet(isPresented: $viewModel.showAddToCollection) {
            if let quote = viewModel.selectedQuote {
                AddToCollectionSheet(
                    quote: quote,
                    collections: viewModel.collections,
                    onAdd: { collectionId in
                        Task {
                            await viewModel.addToCollection(quoteId: quote.id, collectionId: collectionId)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Favorite Quote Card

struct FavoriteQuoteCard: View {
    let quote: Quote
    let onUnfavorite: () -> Void
    let onAddToCollection: () -> Void
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
            
            // Actions
            HStack(spacing: 16) {
                Button(action: onUnfavorite) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.slash")
                        Text("Unfavorite")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: onAddToCollection) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.plus")
                        Text("Add to Collection")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    FavoritesView()
}
