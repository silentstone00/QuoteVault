//
//  QuoteCollection.swift
//  QuoteVault
//
//  Collection models for organizing quotes
//

import Foundation

/// User-created collection of quotes
struct QuoteCollection: Codable, Identifiable {
    let id: UUID
    var name: String
    let userId: UUID
    let createdAt: Date
    var quoteCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userId = "user_id"
        case createdAt = "created_at"
        case quoteCount = "quote_count"
    }
}

/// User favorite quote association
struct UserFavorite: Codable {
    let id: UUID
    let userId: UUID
    let quoteId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case quoteId = "quote_id"
        case createdAt = "created_at"
    }
}

/// Association between a collection and a quote
struct CollectionQuote: Codable {
    let id: UUID
    let collectionId: UUID
    let quoteId: UUID
    let addedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case collectionId = "collection_id"
        case quoteId = "quote_id"
        case addedAt = "added_at"
    }
}
