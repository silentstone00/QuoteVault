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
    @State private var toastMessage: String?
    @State private var showToast = false
    
    var body: some View {
        ZStack {
            Color.customBackground
                .ignoresSafeArea()
            
            if viewModel.favorites.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No Favorites Yet",
                    message: "Double tap any quote to add it to your favorites"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.favorites) { quote in
                            QuoteCardView(quote: quote, onFavoriteToggle: { message in
                                showToastMessage(message)
                            })
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
            
            // Toast at bottom
            if showToast, let message = toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showToast = true
        }
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showToast = false
            }
        }
    }
}

#Preview {
    FavoritesView()
}
