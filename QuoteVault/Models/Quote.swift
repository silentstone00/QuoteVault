//
//  Quote.swift
//  QuoteVault
//
//  Quote and QuoteCategory models
//

import Foundation

/// Quote category enumeration
enum QuoteCategory: String, Codable, CaseIterable {
    case motivation
    case love
    case success
    case wisdom
    case humor
    
    var displayName: String {
        rawValue.capitalized
    }
}

/// Quote model representing an inspirational quote
struct Quote: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let author: String
    let category: QuoteCategory
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case author
        case category
        case createdAt = "created_at"
    }
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id
    }
}
