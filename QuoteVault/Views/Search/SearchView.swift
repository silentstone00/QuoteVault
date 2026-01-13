//
//  SearchView.swift
//  QuoteVault
//
//  Search and browse all quotes
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = QuoteListViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $viewModel.searchQuery)
                        .padding()
                    
                    // Category Filter
                    CategoryFilterView(
                        selectedCategory: $viewModel.selectedCategory,
                        onCategorySelected: { category in
                            Task {
                                await viewModel.filterByCategory(category)
                            }
                        }
                    )
                    
                    // Results
                    if viewModel.isLoading && viewModel.quotes.isEmpty {
                        Spacer()
                        LoadingView()
                        Spacer()
                    } else if viewModel.quotes.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: viewModel.isSearching ? "No Results" : "Search Quotes",
                            message: viewModel.isSearching ? "Try different keywords or filters" : "Search by quote text or author name"
                        )
                        Spacer()
                    } else {
                        ScrollView {
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
                            .padding(.vertical)
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
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
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if viewModel.quotes.isEmpty {
                    await viewModel.loadQuotes()
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(ThemeManager())
}
