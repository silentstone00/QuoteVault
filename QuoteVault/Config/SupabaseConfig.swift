//
//  SupabaseConfig.swift
//  QuoteVault
//
//  Supabase client configuration and initialization
//

import Foundation
import Supabase

/// Configuration and initialization for Supabase client
class SupabaseConfig {
    /// Shared Supabase client instance
    static let shared: SupabaseClient = {
        // Read from environment variables or Info.plist
        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? 
                Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? 
                Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("Supabase URL and Anon Key must be set in environment variables or Info.plist")
        }
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }
        
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
    }()
    
    /// Private initializer to prevent instantiation
    private init() {}
}
