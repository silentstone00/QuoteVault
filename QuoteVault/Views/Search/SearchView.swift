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
    @State private var showFilterSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.customBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Dismiss keyboard when tapping background
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                VStack(spacing: 0) {
                    // Search Bar with Filter
                    SearchBar(text: $viewModel.searchQuery, onFilterTap: {
                        showFilterSheet = true
                    })
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
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
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(
                    selectedCategory: $viewModel.selectedCategory,
                    onApply: {
                        Task {
                            await viewModel.filterByCategory(viewModel.selectedCategory)
                        }
                        showFilterSheet = false
                    },
                    onClear: {
                        viewModel.selectedCategory = nil
                        Task {
                            await viewModel.filterByCategory(nil)
                        }
                        showFilterSheet = false
                    }
                )
                .presentationDetents([.medium])
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

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedCategory: QuoteCategory?
    let onApply: () -> Void
    let onClear: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 12)
            
            // Title
            Text("Filter by Category")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 16)
            
            // Category Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(QuoteCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            selectedCategory = category
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 10) {
                if selectedCategory != nil {
                    Button(action: onClear) {
                        Text("Clear")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                
                Button(action: onApply) {
                    Text(selectedCategory == nil ? "Show All" : "Apply")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.customCard)
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: QuoteCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 20))
                        .foregroundColor(categoryColor)
                }
                
                // Name
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? categoryColor.opacity(0.05) : Color.customCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? categoryColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .motivation: return "flame.fill"
        case .love: return "heart.fill"
        case .success: return "star.fill"
        case .wisdom: return "brain.head.profile"
        case .humor: return "face.smiling"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .motivation: return .orange
        case .love: return .pink
        case .success: return .green
        case .wisdom: return .purple
        case .humor: return .blue
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(ThemeManager())
}
