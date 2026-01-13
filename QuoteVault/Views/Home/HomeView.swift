//
//  HomeView.swift
//  QuoteVault
//
//  Main home screen with QOTD and quote list
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = QuoteListViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Quote of the Day Card
                        if let qotd = viewModel.quoteOfTheDay {
                            QuoteOfTheDayCard(quote: qotd)
                                .environmentObject(themeManager)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        // Category Filter
                        CategoryFilterView(
                            selectedCategory: $viewModel.selectedCategory,
                            onCategorySelected: { category in
                                Task {
                                    await viewModel.filterByCategory(category)
                                }
                            }
                        )
                        
                        // Quote List
                        if viewModel.isLoading && viewModel.quotes.isEmpty {
                            LoadingView()
                                .padding(.top, 40)
                        } else if viewModel.quotes.isEmpty {
                            EmptyStateView(
                                icon: "quote.bubble",
                                title: "No Quotes Found",
                                message: viewModel.isSearching
                                    ? "Try a different search term"
                                    : "Pull to refresh"
                            )
                            .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.quotes) { quote in
                                    QuoteCardView(quote: quote)
                                    .environmentObject(themeManager)
                                        .padding(.horizontal)
                                        .onAppear {
                                            // Infinite scroll trigger
                                            if viewModel.shouldLoadMore(currentQuote: quote) {
                                                Task {
                                                    await viewModel.loadMoreQuotes()
                                                }
                                            }
                                        }
                                }
                                
                                // Loading more indicator
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                
                // Error Alert
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
            .navigationTitle("QuoteVault")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Quote of the Day Card

struct QuoteOfTheDayCard: View {
    let quote: Quote
    @ObservedObject private var collectionViewModel = CollectionViewModel.shared
    @State private var showShareSheet = false
    
    var isFavorited: Bool {
        collectionViewModel.isFavorite(quoteId: quote.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
                Text("Quote of the Day")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
            }
            
            Text(quote.text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack {
                Text("— \(quote.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                CategoryBadge(category: quote.category)
            }
            
            // Actions
            HStack(spacing: 16) {
                // Favorite Button
                Button(action: {
                    Task {
                        await collectionViewModel.toggleFavorite(quote: quote)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                        Text(isFavorited ? "Favorited" : "Favorite")
                            .font(.caption)
                    }
                    .foregroundColor(isFavorited ? .red : .orange)
                }
                
                Spacer()
                
                // Share Button
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showShareSheet) {
            ShareOptionsSheet(quote: quote)
        }
    }
}

#Preview {
    HomeView()
}
