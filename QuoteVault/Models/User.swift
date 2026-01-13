//
//  User.swift
//  QuoteVault
//
//  User and UserPreferences models
//

import Foundation

/// User model representing an authenticated user
struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var displayName: String?
    var avatarUrl: String?
    var preferences: UserPreferences?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case preferences
        case createdAt = "created_at"
    }
}

/// User preferences for theme and notification settings
struct UserPreferences: Codable {
    var colorScheme: String?  // "light", "dark", or nil for system
    var accentColor: String
    var fontSize: String
    var notificationEnabled: Bool
    var notificationTime: String?  // "HH:mm" format
    
    enum CodingKeys: String, CodingKey {
        case colorScheme = "color_scheme"
        case accentColor = "accent_color"
        case fontSize = "font_size"
        case notificationEnabled = "notification_enabled"
        case notificationTime = "notification_time"
    }
    
    /// Default preferences
    init(
        colorScheme: String? = nil,
        accentColor: String = "blue",
        fontSize: String = "medium",
        notificationEnabled: Bool = false,
        notificationTime: String? = nil
    ) {
        self.colorScheme = colorScheme
        self.accentColor = accentColor
        self.fontSize = fontSize
        self.notificationEnabled = notificationEnabled
        self.notificationTime = notificationTime
    }
}
