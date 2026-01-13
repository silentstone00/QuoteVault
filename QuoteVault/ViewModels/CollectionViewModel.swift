//
//  CollectionViewModel.swift
//  QuoteVault
//
//  View model for favorites and collections management
//

import Foundation
import Combine
import SwiftUI

/// View model managing favorites and collections state
@MainActor
class CollectionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var favorites: [Quote] = []
    @Published var collections: [QuoteCollection] = []
    @Published var selectedCollectionQuotes: [Quote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateCollection = false
    @Published var showAddToCollection = false
    @Published var selectedQuote: Quote?
    
    // MARK: - Private Properties
    
    private let collectionManager: CollectionManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(collectionManager: CollectionManagerProtocol = CollectionManager()) {
        self.collectionManager = collectionManager
        
        // Subscribe to favorites changes
        collectionManager.favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favorites in
                self?.favorites = favorites
            }
            .store(in: &cancellables)
        
        // Subscribe to collections changes
        collectionManager.collections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] collections in
                self?.collections = collections
            }
            .store(in: &cancellables)
        
        // Load initial data
        Task {
            await syncFromCloud()
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggle favorite status for a quote
    func toggleFavorite(quote: Quote) async {
        do {
            try await collectionManager.toggleFavorite(quote: quote)
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    /// Check if a quote is favorited
    func isFavorite(quoteId: UUID) -> Bool {
        return collectionManager.isFavorite(quoteId: quoteId)
    }
    
    /// Create a new collection
    func createCollection(name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let collection = try await collectionManager.createCollection(name: name)
            showCreateCollection = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Delete a collection
    func deleteCollection(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await collectionManager.deleteCollection(id: id)
        } catch {
            errorMessage = "Failed to delete collection: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Add quote to collection
    func addToCollection(quoteId: UUID, collectionId: UUID) async {
        do {
            try await collectionManager.addToCollection(quoteId: quoteId, collectionId: collectionId)
            showAddToCollection = false
            selectedQuote = nil
        } catch {
            errorMessage = "Failed to add to collection: \(error.localizedDescription)"
        }
    }
    
    /// Remove quote from collection
    func removeFromCollection(quoteId: UUID, collectionId: UUID) async {
        do {
            try await collectionManager.removeFromCollection(quoteId: quoteId, collectionId: collectionId)
            
            // Refresh collection quotes if viewing this collection
            await loadCollectionQuotes(collectionId: collectionId)
        } catch {
            errorMessage = "Failed to remove from collection: \(error.localizedDescription)"
        }
    }
    
    /// Load quotes in a collection
    func loadCollectionQuotes(collectionId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            selectedCollectionQuotes = try await collectionManager.getQuotesInCollection(collectionId: collectionId)
        } catch {
            errorMessage = "Failed to load collection quotes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Sync from cloud
    func syncFromCloud() async {
        do {
            try await collectionManager.syncFromCloud()
        } catch {
            print("Failed to sync from cloud: \(error.localizedDescription)")
            // Don't show error to user - sync is background operation
        }
    }
    
    /// Show add to collection sheet for a quote
    func showAddToCollectionSheet(for quote: Quote) {
        selectedQuote = quote
        showAddToCollection = true
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
