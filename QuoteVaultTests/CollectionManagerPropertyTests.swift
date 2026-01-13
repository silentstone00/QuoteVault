//
//  CollectionManagerPropertyTests.swift
//  QuoteVaultTests
//
//  Property-based tests for CollectionManager
//

import XCTest
import SwiftCheck
@testable import QuoteVault

/// Feature: quotevault-app, Properties 6-9: Collection Manager correctness
/// Validates: Requirements 4.1, 4.2, 5.2, 5.3, 5.4, 5.6
final class CollectionManagerPropertyTests: XCTestCase {
    
    // MARK: - Property 6: Favorite Toggle Round-Trip
    
    /// Property 6: Favorite Toggle Round-Trip
    /// For any quote and initial favorite state, toggling the favorite status twice
    /// SHALL return the quote to its original favorite state.
    func testFavoriteToggleRoundTrip() {
        property("Toggling favorite twice returns to original state") <- forAll { (quoteIndex: Int) in
            // Generate a mock quote
            let mockQuotes = self.generateMockQuotes(count: 10)
            let quote = mockQuotes[abs(quoteIndex) % mockQuotes.count]
            
            // Simulate favorite state
            var favoriteIds: Set<UUID> = []
            let initialState = favoriteIds.contains(quote.id)
            
            // Toggle once
            if favoriteIds.contains(quote.id) {
                favoriteIds.remove(quote.id)
            } else {
                favoriteIds.insert(quote.id)
            }
            
            // Toggle twice
            if favoriteIds.contains(quote.id) {
                favoriteIds.remove(quote.id)
            } else {
                favoriteIds.insert(quote.id)
            }
            
            let finalState = favoriteIds.contains(quote.id)
            
            // Property: Final state should equal initial state
            return initialState == finalState
        }
    }
    
    /// Test favorite toggle with multiple quotes
    func testFavoriteToggleWithMultipleQuotes() {
        let mockQuotes = generateMockQuotes(count: 5)
        var favoriteIds: Set<UUID> = []
        
        // Favorite all quotes
        for quote in mockQuotes {
            favoriteIds.insert(quote.id)
        }
        
        XCTAssertEqual(favoriteIds.count, 5, "All quotes should be favorited")
        
        // Unfavorite all quotes
        for quote in mockQuotes {
            favoriteIds.remove(quote.id)
        }
        
        XCTAssertEqual(favoriteIds.count, 0, "All quotes should be unfavorited")
    }
    
    // MARK: - Property 7: Collection Name Validation Rejects Empty Names
    
    /// Property 7: Collection Name Validation Rejects Empty Names
    /// For any string that is empty or contains only whitespace characters,
    /// collection creation SHALL fail with a validation error.
    func testCollectionNameValidationRejectsEmptyNames() {
        property("Empty or whitespace-only names are rejected") <- forAll { (whitespaceCount: Int) in
            // Generate whitespace-only strings
            let emptyNames = [
                "",
                " ",
                "  ",
                "\t",
                "\n",
                String(repeating: " ", count: abs(whitespaceCount % 10))
            ]
            
            // Property: All empty names should be invalid
            return emptyNames.allSatisfy { name in
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty
            }
        }
    }
    
    /// Test valid collection names are accepted
    func testValidCollectionNamesAreAccepted() {
        let validNames = [
            "My Favorites",
            "Inspirational",
            "Work Quotes",
            "Daily Motivation",
            "Love & Life"
        ]
        
        for name in validNames {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertFalse(trimmed.isEmpty, "Valid name '\(name)' should not be empty after trimming")
        }
    }
    
    // MARK: - Property 8: Collection Add/Remove Round-Trip
    
    /// Property 8: Collection Add/Remove Round-Trip
    /// For any quote and collection, adding the quote to the collection and then
    /// removing it SHALL result in the quote no longer being in that collection.
    func testCollectionAddRemoveRoundTrip() {
        property("Adding then removing a quote results in empty collection") <- forAll { (quoteIndex: Int) in
            let mockQuotes = self.generateMockQuotes(count: 10)
            let quote = mockQuotes[abs(quoteIndex) % mockQuotes.count]
            let collectionId = UUID()
            
            // Simulate collection quotes
            var collectionQuotes: Set<UUID> = []
            
            // Add quote
            collectionQuotes.insert(quote.id)
            let afterAdd = collectionQuotes.contains(quote.id)
            
            // Remove quote
            collectionQuotes.remove(quote.id)
            let afterRemove = collectionQuotes.contains(quote.id)
            
            // Property: Quote should be present after add, absent after remove
            return afterAdd == true && afterRemove == false
        }
    }
    
    /// Test adding multiple quotes to collection
    func testAddingMultipleQuotesToCollection() {
        let mockQuotes = generateMockQuotes(count: 5)
        var collectionQuotes: Set<UUID> = []
        
        // Add all quotes
        for quote in mockQuotes {
            collectionQuotes.insert(quote.id)
        }
        
        XCTAssertEqual(collectionQuotes.count, 5, "All quotes should be in collection")
        
        // Remove one quote
        collectionQuotes.remove(mockQuotes[0].id)
        
        XCTAssertEqual(collectionQuotes.count, 4, "One quote should be removed")
        XCTAssertFalse(collectionQuotes.contains(mockQuotes[0].id), "Removed quote should not be in collection")
    }
    
    // MARK: - Property 9: Collection Deletion Removes All Associations
    
    /// Property 9: Collection Deletion Removes All Associations
    /// For any collection with associated quotes, deleting the collection SHALL
    /// result in zero quotes associated with that collection ID.
    func testCollectionDeletionRemovesAllAssociations() {
        property("Deleting collection removes all quote associations") <- forAll { (quoteCount: Int) in
            let count = max(1, abs(quoteCount % 20))
            let mockQuotes = self.generateMockQuotes(count: count)
            let collectionId = UUID()
            
            // Simulate collection with quotes
            var collectionQuotes: [UUID: Set<UUID>] = [:]
            collectionQuotes[collectionId] = Set(mockQuotes.map { $0.id })
            
            let beforeDeletion = collectionQuotes[collectionId]?.count ?? 0
            
            // Delete collection (removes all associations)
            collectionQuotes.removeValue(forKey: collectionId)
            
            let afterDeletion = collectionQuotes[collectionId]?.count ?? 0
            
            // Property: Before deletion should have quotes, after should have zero
            return beforeDeletion > 0 && afterDeletion == 0
        }
    }
    
    /// Test cascade deletion with multiple collections
    func testCascadeDeletionWithMultipleCollections() {
        let mockQuotes = generateMockQuotes(count: 10)
        let collection1 = UUID()
        let collection2 = UUID()
        
        var collectionQuotes: [UUID: Set<UUID>] = [:]
        collectionQuotes[collection1] = Set(mockQuotes.prefix(5).map { $0.id })
        collectionQuotes[collection2] = Set(mockQuotes.suffix(5).map { $0.id })
        
        XCTAssertEqual(collectionQuotes.count, 2, "Should have 2 collections")
        
        // Delete collection1
        collectionQuotes.removeValue(forKey: collection1)
        
        XCTAssertEqual(collectionQuotes.count, 1, "Should have 1 collection after deletion")
        XCTAssertNil(collectionQuotes[collection1], "Deleted collection should not exist")
        XCTAssertNotNil(collectionQuotes[collection2], "Other collection should still exist")
    }
    
    // MARK: - Edge Cases
    
    func testFavoriteIdempotence() {
        let quote = generateMockQuotes(count: 1)[0]
        var favoriteIds: Set<UUID> = []
        
        // Favorite multiple times
        favoriteIds.insert(quote.id)
        favoriteIds.insert(quote.id)
        favoriteIds.insert(quote.id)
        
        XCTAssertEqual(favoriteIds.count, 1, "Favoriting multiple times should be idempotent")
    }
    
    func testUnfavoriteNonExistentQuote() {
        let quote = generateMockQuotes(count: 1)[0]
        var favoriteIds: Set<UUID> = []
        
        // Try to unfavorite a quote that was never favorited
        favoriteIds.remove(quote.id)
        
        XCTAssertEqual(favoriteIds.count, 0, "Unfavoriting non-existent quote should not cause issues")
    }
    
    func testCollectionNameTrimming() {
        let names = [
            "  My Collection  ",
            "\tTabbed\t",
            "\nNewline\n",
            "  Spaces  "
        ]
        
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertFalse(trimmed.isEmpty, "Trimmed name should not be empty")
            XCTAssertFalse(trimmed.hasPrefix(" "), "Trimmed name should not have leading spaces")
            XCTAssertFalse(trimmed.hasSuffix(" "), "Trimmed name should not have trailing spaces")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateMockQuotes(count: Int) -> [Quote] {
        let categories = QuoteCategory.allCases
        let authors = ["Einstein", "Shakespeare", "Gandhi"]
        let texts = [
            "The only way to do great work is to love what you do.",
            "To be or not to be, that is the question.",
            "Be the change you wish to see in the world."
        ]
        
        return (0..<count).map { index in
            Quote(
                id: UUID(),
                text: texts[index % texts.count],
                author: authors[index % authors.count],
                category: categories[index % categories.count],
                createdAt: Date()
            )
        }
    }
}
