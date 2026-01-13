//
//  CollectionManager.swift
//  QuoteVault
//
//  Service for managing favorites and collections
//

import Foundation
import Supabase
import Combine

/// Protocol defining collection management operations
protocol CollectionManagerProtocol {
    /// Publisher that emits the current favorites list
    var favorites: AnyPublisher<[Quote], Never> { get }
    
    /// Publisher that emits the current collections list
    var collections: AnyPublisher<[QuoteCollection], Never> { get }
    
    /// Toggle favorite status for a quote
    /// - Parameter quote: The quote to favorite/unfavorite
    func toggleFavorite(quote: Quote) async throws
    
    /// Check if a quote is favorited
    /// - Parameter quoteId: The quote ID to check
    /// - Returns: True if the quote is favorited
    func isFavorite(quoteId: UUID) -> Bool
    
    /// Create a new collection
    /// - Parameter name: The collection name
    /// - Returns: The created collection
    func createCollection(name: String) async throws -> QuoteCollection
    
    /// Delete a collection
    /// - Parameter id: The collection ID to delete
    func deleteCollection(id: UUID) async throws
    
    /// Add a quote to a collection
    /// - Parameters:
    ///   - quoteId: The quote ID to add
    ///   - collectionId: The collection ID to add to
    func addToCollection(quoteId: UUID, collectionId: UUID) async throws
    
    /// Remove a quote from a collection
    /// - Parameters:
    ///   - quoteId: The quote ID to remove
    ///   - collectionId: The collection ID to remove from
    func removeFromCollection(quoteId: UUID, collectionId: UUID) async throws
    
    /// Get all quotes in a collection
    /// - Parameter collectionId: The collection ID
    /// - Returns: Array of quotes in the collection
    func getQuotesInCollection(collectionId: UUID) async throws -> [Quote]
    
    /// Sync favorites and collections from cloud
    func syncFromCloud() async throws
}

/// Collection manager implementation with local caching and cloud sync
class CollectionManager: CollectionManagerProtocol {
    // MARK: - Properties
    
    private let supabase: SupabaseClient
    private let localStorage: LocalStorageProtocol
    private let authService: AuthServiceProtocol
    
    private let favoritesSubject = CurrentValueSubject<[Quote], Never>([])
    private let collectionsSubject = CurrentValueSubject<[QuoteCollection], Never>([])
    
    private var favoriteIds: Set<UUID> = []
    private var cancellables = Set<AnyCancellable>()
    
    var favorites: AnyPublisher<[Quote], Never> {
        favoritesSubject.eraseToAnyPublisher()
    }
    
    var collections: AnyPublisher<[QuoteCollection], Never> {
        collectionsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(
        supabase: SupabaseClient = SupabaseConfig.shared,
        localStorage: LocalStorageProtocol = LocalStorage(),
        authService: AuthServiceProtocol = AuthService()
    ) {
        self.supabase = supabase
        self.localStorage = localStorage
        self.authService = authService
        
        // Load cached data
        loadCachedData()
        
        // Listen for auth state changes
        authService.currentUser
            .sink { [weak self] user in
                if user != nil {
                    Task {
                        try? await self?.syncFromCloud()
                    }
                } else {
                    // Clear data on logout
                    self?.clearData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func toggleFavorite(quote: Quote) async throws {
        if isFavorite(quoteId: quote.id) {
            try await unfavorite(quote: quote)
        } else {
            try await favorite(quote: quote)
        }
    }
    
    func isFavorite(quoteId: UUID) -> Bool {
        return favoriteIds.contains(quoteId)
    }
    
    func createCollection(name: String) async throws -> QuoteCollection {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CollectionError.emptyCollectionName
        }
        
        guard let userId = authService.currentUser.value?.id else {
            throw CollectionError.notAuthenticated
        }
        
        // Create in database
        let newCollection = QuoteCollection(
            id: UUID(),
            name: trimmedName,
            userId: userId,
            createdAt: Date(),
            quoteCount: 0
        )
        
        let response: [QuoteCollection] = try await supabase.database
            .from("collections")
            .insert(newCollection)
            .select()
            .execute()
            .value
        
        guard let created = response.first else {
            throw CollectionError.creationFailed
        }
        
        // Update local state
        var current = collectionsSubject.value
        current.append(created)
        collectionsSubject.send(current)
        
        // Cache
        localStorage.saveCollections(current)
        
        return created
    }
    
    func deleteCollection(id: UUID) async throws {
        // Delete from database (cascade will remove collection_quotes)
        try await supabase.database
            .from("collections")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        // Update local state
        var current = collectionsSubject.value
        current.removeAll { $0.id == id }
        collectionsSubject.send(current)
        
        // Cache
        localStorage.saveCollections(current)
    }
    
    func addToCollection(quoteId: UUID, collectionId: UUID) async throws {
        let collectionQuote = CollectionQuote(
            id: UUID(),
            collectionId: collectionId,
            quoteId: quoteId,
            addedAt: Date()
        )
        
        try await supabase.database
            .from("collection_quotes")
            .insert(collectionQuote)
            .execute()
    }
    
    func removeFromCollection(quoteId: UUID, collectionId: UUID) async throws {
        try await supabase.database
            .from("collection_quotes")
            .delete()
            .eq("collection_id", value: collectionId.uuidString)
            .eq("quote_id", value: quoteId.uuidString)
            .execute()
    }
    
    func getQuotesInCollection(collectionId: UUID) async throws -> [Quote] {
        // Query collection_quotes joined with quotes
        let response: [CollectionQuoteWithQuote] = try await supabase.database
            .from("collection_quotes")
            .select("*, quotes(*)")
            .eq("collection_id", value: collectionId.uuidString)
            .execute()
            .value
        
        return response.compactMap { $0.quote }
    }
    
    func syncFromCloud() async throws {
        guard let userId = authService.currentUser.value?.id else {
            return
        }
        
        // Sync favorites
        let favoriteRecords: [UserFavorite] = try await supabase.database
            .from("user_favorites")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let favoriteQuoteIds = favoriteRecords.map { $0.quoteId }
        
        // Fetch favorite quotes
        if !favoriteQuoteIds.isEmpty {
            let favoriteQuotes: [Quote] = try await supabase.database
                .from("quotes")
                .select()
                .in("id", values: favoriteQuoteIds.map { $0.uuidString })
                .execute()
                .value
            
            favoritesSubject.send(favoriteQuotes)
            favoriteIds = Set(favoriteQuoteIds)
            localStorage.saveFavorites(favoriteQuotes)
        }
        
        // Sync collections
        let userCollections: [QuoteCollection] = try await supabase.database
            .from("collections")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        collectionsSubject.send(userCollections)
        localStorage.saveCollections(userCollections)
    }
    
    // MARK: - Private Methods
    
    private func favorite(quote: Quote) async throws {
        guard let userId = authService.currentUser.value?.id else {
            // Save locally for offline
            var current = favoritesSubject.value
            current.append(quote)
            favoritesSubject.send(current)
            favoriteIds.insert(quote.id)
            localStorage.saveFavorites(current)
            return
        }
        
        // Save to database
        let favorite = UserFavorite(
            id: UUID(),
            userId: userId,
            quoteId: quote.id,
            createdAt: Date()
        )
        
        try await supabase.database
            .from("user_favorites")
            .insert(favorite)
            .execute()
        
        // Update local state
        var current = favoritesSubject.value
        current.append(quote)
        favoritesSubject.send(current)
        favoriteIds.insert(quote.id)
        localStorage.saveFavorites(current)
    }
    
    private func unfavorite(quote: Quote) async throws {
        guard let userId = authService.currentUser.value?.id else {
            // Remove locally
            var current = favoritesSubject.value
            current.removeAll { $0.id == quote.id }
            favoritesSubject.send(current)
            favoriteIds.remove(quote.id)
            localStorage.saveFavorites(current)
            return
        }
        
        // Delete from database
        try await supabase.database
            .from("user_favorites")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("quote_id", value: quote.id.uuidString)
            .execute()
        
        // Update local state
        var current = favoritesSubject.value
        current.removeAll { $0.id == quote.id }
        favoritesSubject.send(current)
        favoriteIds.remove(quote.id)
        localStorage.saveFavorites(current)
    }
    
    private func loadCachedData() {
        let cachedFavorites = localStorage.loadFavorites()
        favoritesSubject.send(cachedFavorites)
        favoriteIds = Set(cachedFavorites.map { $0.id })
        
        let cachedCollections = localStorage.loadCollections()
        collectionsSubject.send(cachedCollections)
    }
    
    private func clearData() {
        favoritesSubject.send([])
        collectionsSubject.send([])
        favoriteIds.removeAll()
        localStorage.clearFavorites()
        localStorage.clearCollections()
    }
}

// MARK: - Local Storage Protocol

/// Protocol for local storage operations
protocol LocalStorageProtocol {
    func saveFavorites(_ favorites: [Quote])
    func loadFavorites() -> [Quote]
    func clearFavorites()
    
    func saveCollections(_ collections: [QuoteCollection])
    func loadCollections() -> [QuoteCollection]
    func clearCollections()
}

/// UserDefaults-based local storage implementation
class LocalStorage: LocalStorageProtocol {
    private let favoritesKey = "cached_favorites"
    private let collectionsKey = "cached_collections"
    
    func saveFavorites(_ favorites: [Quote]) {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    func loadFavorites() -> [Quote] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let favorites = try? JSONDecoder().decode([Quote].self, from: data) else {
            return []
        }
        return favorites
    }
    
    func clearFavorites() {
        UserDefaults.standard.removeObject(forKey: favoritesKey)
    }
    
    func saveCollections(_ collections: [QuoteCollection]) {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: collectionsKey)
        }
    }
    
    func loadCollections() -> [QuoteCollection] {
        guard let data = UserDefaults.standard.data(forKey: collectionsKey),
              let collections = try? JSONDecoder().decode([QuoteCollection].self, from: data) else {
            return []
        }
        return collections
    }
    
    func clearCollections() {
        UserDefaults.standard.removeObject(forKey: collectionsKey)
    }
}

// MARK: - Helper Types

/// Helper type for joining collection_quotes with quotes
struct CollectionQuoteWithQuote: Codable {
    let id: UUID
    let collectionId: UUID
    let quoteId: UUID
    let addedAt: Date
    let quote: Quote?
    
    enum CodingKeys: String, CodingKey {
        case id
        case collectionId = "collection_id"
        case quoteId = "quote_id"
        case addedAt = "added_at"
        case quote = "quotes"
    }
}

// MARK: - Collection Errors

enum CollectionError: LocalizedError {
    case emptyCollectionName
    case notAuthenticated
    case creationFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .emptyCollectionName:
            return "Collection name cannot be empty"
        case .notAuthenticated:
            return "You must be logged in to create collections"
        case .creationFailed:
            return "Failed to create collection"
        case .notFound:
            return "Collection not found"
        }
    }
}
