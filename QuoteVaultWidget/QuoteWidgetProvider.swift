//
//  QuoteWidgetProvider.swift
//  QuoteVaultWidget
//
//  Timeline provider for Quote widget
//

import WidgetKit
import SwiftUI

/// Timeline entry for the quote widget
struct QuoteWidgetEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
    
    /// Placeholder entry for widget preview
    static var placeholder: QuoteWidgetEntry {
        QuoteWidgetEntry(
            date: Date(),
            quote: Quote(
                id: UUID(),
                text: "The only way to do great work is to love what you do.",
                author: "Steve Jobs",
                category: .motivation,
                createdAt: Date()
            )
        )
    }
    
    /// Empty entry when no quote is available
    static var empty: QuoteWidgetEntry {
        QuoteWidgetEntry(date: Date(), quote: nil)
    }
}

/// Timeline provider for the quote widget
struct QuoteWidgetProvider: TimelineProvider {
    
    // MARK: - TimelineProvider Methods
    
    /// Provide placeholder entry for widget gallery
    func placeholder(in context: Context) -> QuoteWidgetEntry {
        return .placeholder
    }
    
    /// Provide snapshot for widget preview
    func getSnapshot(in context: Context, completion: @escaping (QuoteWidgetEntry) -> Void) {
        // For preview, use placeholder
        if context.isPreview {
            completion(.placeholder)
            return
        }
        
        // For actual snapshot, try to load real data
        if let quote = SharedQuoteStorage.loadQuoteOfTheDay() {
            completion(QuoteWidgetEntry(date: Date(), quote: quote))
        } else {
            completion(.placeholder)
        }
    }
    
    /// Provide timeline entries for widget updates
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteWidgetEntry>) -> Void) {
        // Load quote from shared storage
        let quote = SharedQuoteStorage.loadQuoteOfTheDay()
        
        // Create entry for current time
        let currentDate = Date()
        let entry = QuoteWidgetEntry(date: currentDate, quote: quote)
        
        // Calculate next midnight (when widget should refresh)
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        
        // Create timeline with single entry, refresh at midnight
        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextMidnight)
        )
        
        completion(timeline)
    }
}
