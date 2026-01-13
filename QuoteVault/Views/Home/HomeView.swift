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
    @State private var toastMessage: String?
    @State private var showToast = false
    
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
            .navigationTitle("QuoteVault")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - Quote of the Day Card

struct QuoteOfTheDayCard: View {
    let quote: Quote
    @ObservedObject private var collectionViewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showShareSheet = false
    
    var isFavorited: Bool {
        collectionViewModel.isFavorite(quoteId: quote.id)
    }
    
    // Determine text color based on accent color brightness
    var textColor: Color {
        // For darker colors, use white text; for lighter colors, use dark text
        switch themeManager.theme.accentColor {
        case .blue, .purple:
            return .white
        case .orange, .green, .pink:
            return .primary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(textColor.opacity(0.9))
                Text("Quote of the Day")
                    .font(.headline)
                    .foregroundColor(textColor.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Quote Text with quotation marks
            Text("\"\(quote.text)\"")
                .font(.system(size: themeManager.quoteFontSize + 4))
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .lineLimit(nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            
            // Thin divider
            Divider()
                .background(textColor.opacity(0.3))
                .padding(.horizontal, 24)
            
            // Author and Actions
            HStack(spacing: 16) {
                // Author name on left
                Text(quote.author)
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.8))
                
                Spacer()
                
                // Copy icon
                Button(action: {
                    copyToClipboard()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.8))
                }
                
                // Share icon
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.8))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(themeManager.accentColor)
        .cornerRadius(16)
        .sheet(isPresented: $showShareSheet) {
            ShareOptionsSheet(quote: quote)
        }
    }
    
    private func copyToClipboard() {
        let textToCopy = "\"\(quote.text)\" — \(quote.author)"
        UIPasteboard.general.string = textToCopy
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    HomeView()
}
