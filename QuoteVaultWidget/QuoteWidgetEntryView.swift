//
//  QuoteWidgetEntryView.swift
//  QuoteVaultWidget
//
//  UI view for the quote widget
//

import SwiftUI
import WidgetKit

// Dark background color from app (RGB: 0.039, 0.051, 0.071)
private let widgetBackground = Color(red: 0.039, green: 0.051, blue: 0.071)

/// Main view for the quote widget
struct QuoteWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: QuoteWidgetEntry
    
    var body: some View {
        if let quote = entry.quote {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(quote: quote)
            case .systemMedium:
                MediumWidgetView(quote: quote)
            default:
                MediumWidgetView(quote: quote)
            }
        } else {
            EmptyWidgetView()
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Large opening quote mark
            Text("\u{201C}")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(categoryColor.opacity(0.5))
                .frame(height: 32)
                .offset(x: -4, y: 0)
            
            Spacer(minLength: 4)
            
            // Quote text
            Text(quote.text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .lineLimit(4)
                .foregroundColor(.white)
                .minimumScaleFactor(0.85)
            
            Spacer(minLength: 8)
            
            // Author with accent line
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(categoryColor)
                    .frame(width: 16, height: 2)
                
                Text(quote.author)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            widgetBackground
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
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 4)
                .padding(.vertical, 16)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack {
                    // Large quote mark
                    Text("\u{201C}")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundColor(categoryColor.opacity(0.4))
                        .frame(width: 30, height: 30)
                        .offset(y: 4)
                    
                    Spacer()
                    
                    // Category pill
                    Text(quote.category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(categoryColor.opacity(0.2))
                        )
                }
                
                // Quote text - increased font and more lines
                Text(quote.text)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .lineLimit(4)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.85)
                
                Spacer(minLength: 4)
                
                // Author
                HStack(spacing: 8) {
                    Circle()
                        .fill(categoryColor.opacity(0.25))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Text(String(quote.author.prefix(1)))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(categoryColor)
                        )
                    
                    Text(quote.author)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
        }
        .containerBackground(for: .widget) {
            widgetBackground
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
        VStack(spacing: 10) {
            // Quote icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 52, height: 52)
                
                Image(systemName: "quote.bubble")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                Text("No Quote Yet")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Open app to get started")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
}

// MARK: - Preview

struct QuoteWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuoteWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")
            
            QuoteWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")
            
            QuoteWidgetEntryView(entry: .empty)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Empty")
        }
    }
}
