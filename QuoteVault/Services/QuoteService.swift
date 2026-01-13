//
//  QuoteService.swift
//  QuoteVault
//
//  Service for fetching, searching, and managing quotes
//

import Foundation
import Supabase
import Combine

/// Search type for quote queries
enum SearchType {
    case keyword
    case author
}

/// Protocol defining quote service operations
protocol QuoteServiceProtocol {
    /// Fetch paginated quotes with optional category filter
    /// - Parameters:
    ///   - page: Page number (0-indexed)
    ///   - pageSize: Number of quotes per page
    ///   - category: Optional category filter
    /// - Returns: Array of quotes
    func fetchQuotes(page: Int, pageSize: Int, category: QuoteCategory?) async throws -> [Quote]
    
    /// Search quotes by keyword or author
    /// - Parameters:
    ///   - query: Search query string
    ///   - searchType: Type of search (keyword or author)
    /// - Returns: Array of matching quotes
    func searchQuotes(query: String, searchType: SearchType) async throws -> [Quote]
    
    /// Get the Quote of the Day
    /// - Returns: The quote of the day
    func getQuoteOfTheDay() async throws -> Quote
    
    /// Refresh quotes (clears cache and fetches fresh data)
    /// - Returns: Array of refreshed quotes
    func refreshQuotes() async throws -> [Quote]
}

/// Quote service implementation using Supabase
class QuoteService: QuoteServiceProtocol {
    // MARK: - Properties
    
    private let supabase: SupabaseClient
    private let cache: QuoteCacheProtocol
    private let pageSize = 20
    
    // MARK: - Initialization
    
    init(
        supabase: SupabaseClient = SupabaseConfig.shared,
        cache: QuoteCacheProtocol = QuoteCache()
    ) {
        self.supabase = supabase
        self.cache = cache
    }
    
    // MARK: - Public Methods
    
    func fetchQuotes(page: Int, pageSize: Int = 20, category: QuoteCategory? = nil) async throws -> [Quote] {
        // Build query
        var query = supabase.database
            .from("quotes")
            .select()
        
        // Apply category filter if provided
        if let category = category {
            query = query.eq("category", value: category.rawValue)
        }
        
        // Apply pagination
        let from = page * pageSize
        let to = from + pageSize - 1
        query = query.range(from: from, to: to)
        
        // Order by created_at descending
        query = query.order("created_at", ascending: false)
        
        // Execute query
        let response: [Quote] = try await query.execute().value
        
        // Cache the results
        cache.cacheQuotes(response)
        
        return response
    }
    
    func searchQuotes(query: String, searchType: SearchType) async throws -> [Quote] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            // Return empty array for empty search
            return []
        }
        
        // Use the search_quotes function from the database
        let response: [Quote] = try await supabase.database
            .rpc("search_quotes", params: [
                "search_query": trimmedQuery,
                "search_category": nil as String?,
                "page_num": 0,
                "page_size": 100
            ])
            .execute()
            .value
        
        // Filter by search type if needed
        switch searchType {
        case .keyword:
            // Already filtered by the function
            return response
        case .author:
            // Filter to only author matches
            return response.filter { quote in
                quote.author.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }
    }
    
    func getQuoteOfTheDay() async throws -> Quote {
        // Check cache first
        if let cachedQOTD = cache.getCachedQuoteOfTheDay() {
            return cachedQOTD
        }
        
        // Use the get_quote_of_day function from the database
        let response: [Quote] = try await supabase.database
            .rpc("get_quote_of_day", params: [:])
            .execute()
            .value
        
        guard let quote = response.first else {
            throw QuoteServiceError.quoteOfTheDayNotFound
        }
        
        // Cache the QOTD
        cache.cacheQuoteOfTheDay(quote)
        
        return quote
    }
    
    func refreshQuotes() async throws -> [Quote] {
        // Clear cache
        cache.clearCache()
        
        // Fetch fresh quotes
        return try await fetchQuotes(page: 0, pageSize: pageSize)
    }
}

// MARK: - Quote Cache Protocol

/// Protocol for caching quotes
protocol QuoteCacheProtocol {
    func cacheQuotes(_ quotes: [Quote])
    func getCachedQuotes() -> [Quote]
    func cacheQuoteOfTheDay(_ quote: Quote)
    func getCachedQuoteOfTheDay() -> Quote?
    func clearCache()
}

/// In-memory cache implementation for quotes
class QuoteCache: QuoteCacheProtocol {
    private var quotesCache: [Quote] = []
    private var qotdCache: (quote: Quote, date: Date)?
    private let calendar = Calendar.current
    
    func cacheQuotes(_ quotes: [Quote]) {
        quotesCache = quotes
    }
    
    func getCachedQuotes() -> [Quote] {
        return quotesCache
    }
    
    func cacheQuoteOfTheDay(_ quote: Quote) {
        qotdCache = (quote, Date())
    }
    
    func getCachedQuoteOfTheDay() -> Quote? {
        guard let cached = qotdCache else {
            return nil
        }
        
        // Check if cached QOTD is from today
        let cachedDate = calendar.startOfDay(for: cached.date)
        let today = calendar.startOfDay(for: Date())
        
        if cachedDate == today {
            return cached.quote
        }
        
        // Cache is stale
        return nil
    }
    
    func clearCache() {
        quotesCache = []
        qotdCache = nil
    }
}

// MARK: - Quote Service Errors

enum QuoteServiceError: LocalizedError {
    case quoteOfTheDayNotFound
    case searchFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .quoteOfTheDayNotFound:
            return "Quote of the day not found"
        case .searchFailed:
            return "Search failed"
        case .networkError:
            return "Network error occurred"
        }
    }
}
