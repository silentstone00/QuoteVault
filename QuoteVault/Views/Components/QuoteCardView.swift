//
//  QuoteCardView.swift
//  QuoteVault
//
//  Individual quote card component
//

import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    @ObservedObject private var collectionViewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showShareSheet = false
    @State private var showCopyFeedback = false
    let onFavoriteToggle: ((String) -> Void)?
    
    var isFavorited: Bool {
        collectionViewModel.isFavorite(quoteId: quote.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Quote Text with quotation marks
            Text("\"\(quote.text)\"")
                .font(.system(size: themeManager.quoteFontSize + 2))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            
            // Thin divider
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 24)
            
            // Author and Actions
            HStack(spacing: 16) {
                // Author name on left
                Text(quote.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Copy icon
                Button(action: {
                    copyToClipboard()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                // Share icon
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFavorited ? Color.pink : Color.clear, lineWidth: 2)
        )
        .onTapGesture(count: 2) {
            handleDoubleTap()
        }
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
        
        // Show feedback
        showCopyFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCopyFeedback = false
        }
    }
    
    private func handleDoubleTap() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            let wasFavorited = isFavorited
            await collectionViewModel.toggleFavorite(quote: quote)
            
            // Notify parent view to show toast
            await MainActor.run {
                let message = wasFavorited ? "Removed from Favorites" : "Added to Favorites"
                onFavoriteToggle?(message)
            }
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
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
    QuoteCardView(
        quote: Quote(
            id: UUID(),
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            category: .motivation,
            createdAt: Date()
        ),
        onFavoriteToggle: nil
    )
    .padding()
}
