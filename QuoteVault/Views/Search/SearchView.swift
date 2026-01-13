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
    @State private var toastMessage: String?
    @State private var showToast = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $viewModel.searchQuery)
                        .padding()
                    
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
                                    QuoteCardView(quote: quote, onFavoriteToggle: { message in
                                        showToastMessage(message)
                                    })
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
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if viewModel.quotes.isEmpty {
                    await viewModel.loadQuotes()
                }
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
    SearchView()
        .environmentObject(ThemeManager())
}
