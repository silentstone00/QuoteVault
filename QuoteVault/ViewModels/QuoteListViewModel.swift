//
//  QuoteListViewModel.swift
//  QuoteVault
//
//  View model for quote browsing and discovery
//

import Foundation
import Combine
import SwiftUI

/// View model managing quote list state and operations
@MainActor
class QuoteListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var quotes: [Quote] = []
    @Published var quoteOfTheDay: Quote?
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedCategory: QuoteCategory?
    @Published var searchQuery = ""
    @Published var hasMorePages = true
    
    // MARK: - Private Properties
    
    private let quoteService: QuoteServiceProtocol
    private var currentPage = 0
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var filteredQuotes: [Quote] {
        quotes
    }
    
    // MARK: - Initialization
    
    init(quoteService: QuoteServiceProtocol = QuoteService()) {
        self.quoteService = quoteService
        
        // Set up search debouncing
        setupSearchDebouncing()
        
        // Load initial data
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load initial quotes and QOTD
    func loadInitialData() async {
        await loadQuoteOfTheDay()
        await loadQuotes()
    }
    
    /// Load quotes for current page
    func loadQuotes() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedQuotes = try await quoteService.fetchQuotes(
                page: currentPage,
                pageSize: pageSize,
                category: selectedCategory
            )
            
            if currentPage == 0 {
                quotes = fetchedQuotes
            } else {
                quotes.append(contentsOf: fetchedQuotes)
            }
            
            // Check if there are more pages
            hasMorePages = fetchedQuotes.count == pageSize
            
        } catch {
            errorMessage = "Failed to load quotes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load more quotes (infinite scroll)
    func loadMoreQuotes() async {
        guard !isLoadingMore && hasMorePages && !isSearching else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let fetchedQuotes = try await quoteService.fetchQuotes(
                page: currentPage,
                pageSize: pageSize,
                category: selectedCategory
            )
            
            // Filter out duplicates before appending
            let newQuotes = fetchedQuotes.filter { newQuote in
                !quotes.contains(where: { $0.id == newQuote.id })
            }
            
            quotes.append(contentsOf: newQuotes)
            hasMorePages = fetchedQuotes.count == pageSize
            
        } catch {
            errorMessage = "Failed to load more quotes"
            currentPage -= 1 // Revert page increment on error
        }
        
        isLoadingMore = false
    }
    
    /// Refresh quotes (pull-to-refresh)
    func refresh() async {
        currentPage = 0
        hasMorePages = true
        errorMessage = nil
        
        // Try up to 2 times with retry
        var attempts = 0
        let maxAttempts = 2
        
        while attempts < maxAttempts {
            do {
                let fetchedQuotes = try await quoteService.refreshQuotes()
                quotes = fetchedQuotes
                
                // Also refresh QOTD
                await loadQuoteOfTheDay()
                
                // Success - clear any previous error
                return
                
            } catch {
                attempts += 1
                if attempts >= maxAttempts {
                    // Silently fail - just use cached data
                    // Don't show error message to user
                    print("Refresh failed - using cached data: \(error.localizedDescription)")
                } else {
                    // Wait a bit before retry
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
            }
        }
    }
    
    /// Search quotes
    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            // Reset to normal browsing
            currentPage = 0
            await loadQuotes()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let searchResults = try await quoteService.searchQuotes(
                query: query,
                searchType: .keyword
            )
            
            quotes = searchResults
            hasMorePages = false // Search doesn't support pagination
            
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Filter by category
    func filterByCategory(_ category: QuoteCategory?) async {
        selectedCategory = category
        currentPage = 0
        hasMorePages = true
        await loadQuotes()
    }
    
    /// Clear category filter
    func clearCategoryFilter() async {
        await filterByCategory(nil)
    }
    
    /// Load Quote of the Day
    func loadQuoteOfTheDay() async {
        do {
            quoteOfTheDay = try await quoteService.getQuoteOfTheDay()
        } catch {
            print("Failed to load QOTD: \(error.localizedDescription)")
            // Don't show error to user - QOTD is optional
        }
    }
    
    /// Check if should load more (for infinite scroll trigger)
    func shouldLoadMore(currentQuote quote: Quote) -> Bool {
        guard let lastQuote = quotes.last else {
            return false
        }
        
        // Trigger load more when reaching the 5th quote from the end
        let threshold = max(0, quotes.count - 5)
        if let index = quotes.firstIndex(where: { $0.id == quote.id }),
           index >= threshold {
            return true
        }
        
        return false
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebouncing() {
        // Debounce search input to avoid excessive API calls
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Cancel previous search task
                self.searchTask?.cancel()
                
                // Start new search task
                self.searchTask = Task {
                    await self.search()
                }
            }
            .store(in: &cancellables)
    }
}
