//
//  QuoteCardView.swift
//  QuoteVault
//
//  Individual quote card component
//

import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    @StateObject private var collectionViewModel = CollectionViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showShareSheet = false
    
    var isFavorited: Bool {
        collectionViewModel.isFavorite(quoteId: quote.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote Text
            Text(quote.text)
                .font(.system(size: themeManager.quoteFontSize))
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // Author and Category
            HStack {
                Text("— \(quote.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                CategoryBadge(category: quote.category)
            }
            
            // Actions
            HStack(spacing: 16) {
                // Favorite Button
                Button(action: {
                    Task {
                        await collectionViewModel.toggleFavorite(quote: quote)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                        Text(isFavorited ? "Favorited" : "Favorite")
                            .font(.caption)
                    }
                    .foregroundColor(isFavorited ? .red : .gray)
                }
                
                Spacer()
                
                // Share Button
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .sheet(isPresented: $showShareSheet) {
            ShareOptionsSheet(quote: quote)
        }
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: QuoteCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor.opacity(0.2))
            .foregroundColor(categoryColor)
            .cornerRadius(8)
    }
    
    private var categoryColor: Color {
        switch category {
        case .motivation:
            return .orange
        case .love:
            return .pink
        case .success:
            return .green
        case .wisdom:
            return .purple
        case .humor:
            return .blue
        }
    }
}

#Preview {
    QuoteCardView(quote: Quote(
        id: UUID(),
        text: "The only way to do great work is to love what you do.",
        author: "Steve Jobs",
        category: .motivation,
        createdAt: Date()
    ))
    .padding()
}
