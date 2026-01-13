//
//  WidgetUpdateService.swift
//  QuoteVault
//
//  Service to update widget with Quote of the Day
//

import Foundation
import WidgetKit

/// Service to manage widget updates
class WidgetUpdateService {
    
    /// Update widget with new Quote of the Day
    static func updateWidget(with quote: Quote) {
        // Save quote to shared storage
        SharedQuoteStorage.saveQuoteOfTheDay(quote)
        
        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
        
        print("Widget updated with new QOTD: \(quote.text)")
    }
    
    /// Reload widget timelines
    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("Widget timelines reloaded")
    }
    
    /// Check if widget needs update and update if necessary
    static func updateIfNeeded(quoteService: QuoteServiceProtocol) async {
        // Check if we need to update (different day)
        guard SharedQuoteStorage.needsUpdate() else {
            print("Widget does not need update (same day)")
            return
        }
        
        // Fetch new QOTD
        do {
            let quote = try await quoteService.getQuoteOfTheDay()
            updateWidget(with: quote)
        } catch {
            print("Failed to fetch QOTD for widget: \(error)")
        }
    }
}
