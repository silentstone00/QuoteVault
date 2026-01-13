//
//  QuoteWidgetEntryView.swift
//  QuoteVaultWidget
//
//  UI view for the quote widget
//

import SwiftUI
import WidgetKit

/// Main view for the quote widget
struct QuoteWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: QuoteWidgetEntry
    
    var body: some View {
        if let quote = entry.quote {
            // Display quote
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(quote: quote)
            case .systemMedium:
                MediumWidgetView(quote: quote)
            default:
                MediumWidgetView(quote: quote)
            }
        } else {
            // No quote available
            EmptyWidgetView()
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Quote icon
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 16))
                .foregroundColor(categoryColor)
            
            Spacer()
            
            // Quote text with quotation marks
            Text("\"\(quote.text)\"")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(5)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.9)
            
            Spacer()
            
            // Author
            Text("— \(quote.author)")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var categoryColor: Color {
        switch quote.category {
        case .motivation: return .blue
        case .love: return .pink
        case .success: return .green
        case .wisdom: return .purple
        case .humor: return .orange
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let quote: Quote
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Icon
            VStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 36))
                    .foregroundColor(categoryColor)
                
                Spacer()
                
                // Category badge
                Text(quote.category.rawValue.capitalized)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(categoryColor)
                    .cornerRadius(6)
                    .fixedSize()
                    .lineLimit(1)
            }
            .frame(width: 50)
            
            // Right side - Quote content
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text("Quote of the Day")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Quote text with quotation marks
                Text("\"\(quote.text)\"")
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.9)
                
                Spacer()
                
                // Author
                Text("— \(quote.author)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var categoryColor: Color {
        switch quote.category {
        case .motivation: return .blue
        case .love: return .pink
        case .success: return .green
        case .wisdom: return .purple
        case .humor: return .orange
        }
    }
}

// MARK: - Empty Widget View

struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Open QuoteVault")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("to see your daily quote")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview

struct QuoteWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small widget preview
            QuoteWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")
            
            // Medium widget preview
            QuoteWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")
            
            // Empty state preview
            QuoteWidgetEntryView(entry: .empty)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Empty")
        }
    }
}
