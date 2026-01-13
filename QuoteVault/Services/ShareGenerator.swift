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
    case dark       // Dark moody background with light text
    case gradient   // Colorful gradient background
    case photo      // Custom photo background
    
    var displayName: String {
        rawValue.capitalized
    }
}

/// Protocol defining share generation operations
protocol ShareGeneratorProtocol {
    /// Generate plain text for sharing
    func generateShareText(quote: Quote) -> String
    
    /// Generate a styled quote card image
    func generateQuoteCard(quote: Quote, style: CardStyle, customPhoto: UIImage?, gradientColors: [Color]?) async -> UIImage
    
    /// Save image to photo library
    func saveToPhotoLibrary(image: UIImage) async throws
    
    /// Generate random gradient colors
    func generateRandomGradient() -> [Color]
}

/// Share generator implementation
class ShareGenerator: ShareGeneratorProtocol {
    
    func generateShareText(quote: Quote) -> String {
        return "\"\(quote.text)\"\n\n— \(quote.author)"
    }
    
    func generateQuoteCard(quote: Quote, style: CardStyle, customPhoto: UIImage? = nil, gradientColors: [Color]? = nil) async -> UIImage {
        let cardView = QuoteCardStyleView(quote: quote, style: style, customPhoto: customPhoto, gradientColors: gradientColors)
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
    
    func generateRandomGradient() -> [Color] {
        let gradients: [[Color]] = [
            [Color.orange, Color.pink],
            [Color.pink, Color.purple],
            [Color.green, Color.blue],
            [Color.purple, Color.blue],
            [Color.blue, Color.cyan],
            [Color.red, Color.orange],
            [Color.indigo, Color.purple],
            [Color.teal, Color.green],
            [Color.yellow, Color.orange],
            [Color.mint, Color.cyan]
        ]
        return gradients.randomElement() ?? [Color.orange, Color.pink]
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func renderView<Content: View>(_ view: Content) -> UIImage {
        let controller = UIHostingController(rootView: view)
        let hostView = controller.view!
        
        // Set size for the card (Instagram square format)
        let targetSize = CGSize(width: 1080, height: 1080)
        hostView.frame = CGRect(origin: .zero, size: targetSize)
        hostView.backgroundColor = .clear
        
        // Add to window temporarily to ensure proper rendering
        let window = UIWindow(frame: CGRect(origin: .zero, size: targetSize))
        window.addSubview(hostView)
        window.makeKeyAndVisible()
        
        // Force layout
        hostView.setNeedsLayout()
        hostView.layoutIfNeeded()
        
        // Render to image
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let image = renderer.image { _ in
            hostView.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
        
        // Clean up
        hostView.removeFromSuperview()
        
        return image
    }
}

// MARK: - Quote Card Style View

struct QuoteCardStyleView: View {
    let quote: Quote
    let style: CardStyle
    let customPhoto: UIImage?
    let gradientColors: [Color]?
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content with semi-transparent overlay for photo background
            if style == .photo {
                Color.black.opacity(0.4)
            }
            
            // Content
            VStack(spacing: 32) {
                Spacer()
                
                // Quote Text
                Text(quote.text)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                
                // Author
                Text("— \(quote.author)")
                    .font(.system(size: 24, weight: .regular))
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
            Rectangle()
                .fill(Color.white)
                .frame(width: 1080, height: 1080)
        case .dark:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 1080, height: 1080)
        case .gradient:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: gradientColors ?? defaultGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 1080, height: 1080)
        case .photo:
            if let photo = customPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 1080, height: 1080)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 1080, height: 1080)
            }
        }
    }
    
    private var textColor: Color {
        style == .minimal ? .black : .white
    }
    
    private var defaultGradientColors: [Color] {
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
