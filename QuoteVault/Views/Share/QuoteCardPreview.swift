//
//  QuoteCardPreview.swift
//  QuoteVault
//
//  Preview of quote card before generation
//

import SwiftUI

struct QuoteCardPreview: View {
    let quote: Quote
    let style: CardStyle
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            VStack(spacing: 16) {
                Spacer()
                
                // Quote Text
                Text(quote.text)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineLimit(6)
                
                // Author
                Text("— \(quote.author)")
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.8))
                
                Spacer()
                
                // Branding
                HStack(spacing: 4) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.caption)
                    Text("QuoteVault")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(textColor.opacity(0.6))
                .padding(.bottom, 20)
            }
        }
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .minimal:
            Color.white
        case .gradient:
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var textColor: Color {
        style == .minimal ? .black : .white
    }
    
    private var gradientColors: [Color] {
        switch quote.category {
        case .motivation:
            return [Color.orange, Color.pink]
        case .love:
            return [Color.pink, Color.purple]
        case .success:
            return [Color.green, Color.blue]
        case .wisdom:
            return [Color.purple, Color.blue]
        case .humor:
            return [Color.blue, Color.cyan]
        }
    }
}

#Preview {
    QuoteCardPreview(
        quote: Quote(
            id: UUID(),
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            category: .motivation,
            createdAt: Date()
        ),
        style: .gradient
    )
    .frame(height: 300)
    .padding()
}
