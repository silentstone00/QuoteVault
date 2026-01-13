//
//  NotificationScheduler.swift
//  QuoteVault
//
//  Service for scheduling daily quote notifications
//

import Foundation
import UserNotifications
import UIKit

/// Protocol defining notification scheduling operations
protocol NotificationSchedulerProtocol {
    /// Request notification permission from user
    /// - Returns: True if permission granted, false otherwise
    func requestPermission() async throws -> Bool
    
    /// Schedule daily notification at specified time
    /// - Parameters:
    ///   - time: Time components for when to send notification
    ///   - quote: Quote to include in notification
    func scheduleDaily(at time: DateComponents, quote: Quote) async throws
    
    /// Cancel all pending notifications
    func cancelAllNotifications() async
    
    /// Update notification time
    /// - Parameter time: New time components for notifications
    func updateNotificationTime(_ time: DateComponents) async throws
    
    /// Check if notifications are authorized
    /// - Returns: True if authorized, false otherwise
    func isAuthorized() async -> Bool
}

/// Notification scheduler implementation using UNUserNotificationCenter
class NotificationScheduler: NotificationSchedulerProtocol {
    // MARK: - Properties
    
    private let notificationCenter: UNUserNotificationCenter
    private let notificationIdentifier = "daily_quote_notification"
    
    // MARK: - Initialization
    
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }
    
    // MARK: - Public Methods
    
    func requestPermission() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized:
            return true
        case .notDetermined:
            // Request permission
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        case .denied, .provisional, .ephemeral:
            return false
        @unknown default:
            return false
        }
    }
    
    func scheduleDaily(at time: DateComponents, quote: Quote) async throws {
        // Cancel existing notifications first
        await cancelAllNotifications()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Quote of the Day"
        content.body = "\"\(quote.text)\" — \(quote.author)"
        content.sound = .default
        content.badge = 1
        
        // Add quote ID to userInfo for deep linking
        content.userInfo = ["quoteId": quote.id.uuidString]
        
        // Create daily trigger
        var triggerDate = time
        triggerDate.calendar = Calendar.current
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: true
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        try await notificationCenter.add(request)
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [notificationIdentifier]
        )
        
        // Reset badge count
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func updateNotificationTime(_ time: DateComponents) async throws {
        // Get pending notifications to retrieve the quote
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        
        // Find our notification
        if let existingRequest = pendingRequests.first(where: { $0.identifier == notificationIdentifier }) {
            // Extract quote info from existing notification
            let content = existingRequest.content
            
            // Cancel old notification
            await cancelAllNotifications()
            
            // Create new notification with updated time
            let newContent = UNMutableNotificationContent()
            newContent.title = content.title
            newContent.body = content.body
            newContent.sound = content.sound
            newContent.badge = content.badge
            newContent.userInfo = content.userInfo
            
            // Create new trigger with updated time
            var triggerDate = time
            triggerDate.calendar = Calendar.current
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: triggerDate,
                repeats: true
            )
            
            // Create new request
            let request = UNNotificationRequest(
                identifier: notificationIdentifier,
                content: newContent,
                trigger: trigger
            )
            
            // Schedule notification
            try await notificationCenter.add(request)
        }
    }
    
    func isAuthorized() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

// MARK: - Notification Errors

enum NotificationError: LocalizedError {
    case permissionDenied
    case schedulingFailed
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission denied. Please enable notifications in Settings."
        case .schedulingFailed:
            return "Failed to schedule notification"
        case .notAuthorized:
            return "Notifications are not authorized"
        }
    }
}
