//
//  SharedQuoteStorage.swift
//  QuoteVault
//
//  Shared storage for Quote of the Day between app and widget
//

import Foundation

/// Shared storage for Quote of the Day using App Groups
class SharedQuoteStorage {
    // IMPORTANT: Replace "yourname" with your actual organization identifier
    // This MUST match the App Group you create in Xcode
    private static let appGroupIdentifier = "group.com.app.QuoteVault"
    
    private static let qotdKey = "quote_of_the_day"
    private static let qotdDateKey = "quote_of_the_day_date"
    
    /// Get shared UserDefaults for app group
    private static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Save Quote of the Day to shared storage
    static func saveQuoteOfTheDay(_ quote: Quote) {
        guard let defaults = sharedDefaults else {
            print("Failed to access shared UserDefaults")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(quote)
            
            defaults.set(data, forKey: qotdKey)
            defaults.set(Date(), forKey: qotdDateKey)
            defaults.synchronize()
            
            print("Saved QOTD to shared storage: \(quote.text)")
        } catch {
            print("Failed to encode quote: \(error)")
        }
    }
    
    /// Load Quote of the Day from shared storage
    static func loadQuoteOfTheDay() -> Quote? {
        guard let defaults = sharedDefaults else {
            print("Failed to access shared UserDefaults")
            return nil
        }
        
        guard let data = defaults.data(forKey: qotdKey) else {
            print("No QOTD data found in shared storage")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let quote = try decoder.decode(Quote.self, from: data)
            
            print("Loaded QOTD from shared storage: \(quote.text)")
            return quote
        } catch {
            print("Failed to decode quote: \(error)")
            return nil
        }
    }
    
    /// Get the date when QOTD was last updated
    static func getLastUpdateDate() -> Date? {
        guard let defaults = sharedDefaults else {
            return nil
        }
        
        return defaults.object(forKey: qotdDateKey) as? Date
    }
    
    /// Check if QOTD needs to be updated (different day)
    static func needsUpdate() -> Bool {
        guard let lastUpdate = getLastUpdateDate() else {
            return true // No previous update
        }
        
        let calendar = Calendar.current
        let lastUpdateDay = calendar.startOfDay(for: lastUpdate)
        let today = calendar.startOfDay(for: Date())
        
        return lastUpdateDay != today
    }
}
