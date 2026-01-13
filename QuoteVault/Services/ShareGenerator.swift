//
//  ShareGenerator.swift
//  QuoteVault
//
//  Service for generating shareable quote cards
//

import Foundation
import SwiftUI
import UIKit
import Photos

/// Card style options for quote sharing
enum CardStyle: String, CaseIterable {
    case minimal    // Clean white background, simple typography
    case gradient   // Colorful gradient background
    case dark       // Dark moody background with light text
    
    var displayName: String {
        rawValue.capitalized
    }
}

/// Protocol defining share generation operations
protocol ShareGeneratorProtocol {
    /// Generate plain text for sharing
    func generateShareText(quote: Quote) -> String
    
    /// Generate a styled quote card image
    func generateQuoteCard(quote: Quote, style: CardStyle) async -> UIImage
    
    /// Save image to photo library
    func saveToPhotoLibrary(image: UIImage) async throws
}

/// Share generator implementation
class ShareGenerator: ShareGeneratorProtocol {
    
    func generateShareText(quote: Quote) -> String {
        return "\"\(quote.text)\"\n\n— \(quote.author)"
    }
    
    func generateQuoteCard(quote: Quote, style: CardStyle) async -> UIImage {
        let cardView = QuoteCardStyleView(quote: quote, style: style)
        return await renderView(cardView)
    }
    
    func saveToPhotoLibrary(image: UIImage) async throws {
        // Request permission
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        guard status == .authorized else {
            throw ShareError.photoLibraryAccessDenied
        }
        
        // Save image
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func renderView<Content: View>(_ view: Content) -> UIImage {
        let controller = UIHostingController(rootView: view)
        let view = controller.view!
        
        // Set size for the card (Instagram square format)
        let targetSize = CGSize(width: 1080, height: 1080)
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .clear
        
        // Render to image
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Quote Card Style View

struct QuoteCardStyleView: View {
    let quote: Quote
    let style: CardStyle
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            VStack(spacing: 32) {
                Spacer()
                
                // Quote Text
                Text(quote.text)
                    .font(.system(size: 36, weight: .medium, design: .serif))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                
                // Author
                Text("— \(quote.author)")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(textColor.opacity(0.8))
                
                Spacer()
                
                // Branding
                HStack(spacing: 8) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 20))
                    Text("QuoteVault")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(textColor.opacity(0.6))
                .padding(.bottom, 40)
            }
        }
        .frame(width: 1080, height: 1080)
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
        switch style {
        case .minimal:
            return .black
        case .gradient:
            return .white
        case .dark:
            return .white
        }
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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Share Errors

enum ShareError: LocalizedError {
    case photoLibraryAccessDenied
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo library access denied. Please enable it in Settings."
        case .saveFailed:
            return "Failed to save image to photo library"
        }
    }
}
