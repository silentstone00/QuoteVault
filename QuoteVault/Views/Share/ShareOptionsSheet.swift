//
//  ShareOptionsSheet.swift
//  QuoteVault
//
//  Sheet for selecting share options
//

import SwiftUI

struct ShareOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let quote: Quote
    @State private var selectedStyle: CardStyle = .minimal
    @State private var selectedPhoto: UIImage?
    @State private var currentGradient: [Color] = [Color.orange, Color.pink]
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    private let shareGenerator = ShareGenerator()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        QuoteCardPreview(
                            quote: quote,
                            style: selectedStyle,
                            customPhoto: selectedPhoto,
                            gradientColors: currentGradient
                        )
                        .frame(height: 300)
                        .padding(.horizontal)
                    }
                    
                    // Style Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Background Style")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CardStylePicker(
                            selectedStyle: $selectedStyle,
                            selectedPhoto: $selectedPhoto,
                            currentGradient: $currentGradient,
                            onRandomGradient: {
                                currentGradient = shareGenerator.generateRandomGradient()
                            }
                        )
                    }
                    
                    // Main Actions
                    HStack(spacing: 12) {
                        // Share as Image Button
                        Button(action: {
                            Task {
                                await shareAsImage()
                            }
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "photo")
                                    Text("Share as Image")
                                        .font(.subheadline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isGenerating || (selectedStyle == .photo && selectedPhoto == nil))
                        
                        // Share as Text Button
                        Button(action: {
                            shareText()
                        }) {
                            HStack {
                                Image(systemName: "text.quote")
                                Text("Share as Text")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isGenerating)
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Share Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !shareItems.isEmpty {
                    ActivityViewController(activityItems: shareItems)
                }
            }
        }
        .onAppear {
            // Initialize gradient based on quote category
            currentGradient = getDefaultGradient()
        }
        .overlay {
            // Loading overlay
            if isGenerating {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Preparing...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                }
            }
        }
    }
    
    private func shareAsImage() async {
        isGenerating = true
        errorMessage = nil
        
        let image = await shareGenerator.generateQuoteCard(
            quote: quote,
            style: selectedStyle,
            customPhoto: selectedPhoto,
            gradientColors: selectedStyle == .gradient ? currentGradient : nil
        )
        
        isGenerating = false
        
        // Set share items and show share sheet
        shareItems = [image]
        showShareSheet = true
    }
    
    private func shareText() {
        let text = shareGenerator.generateShareText(quote: quote)
        shareItems = [text]
        showShareSheet = true
    }
    
    private func getDefaultGradient() -> [Color] {
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

#Preview {
    ShareOptionsSheet(quote: Quote(
        id: UUID(),
        text: "The only way to do great work is to love what you do.",
        author: "Steve Jobs",
        category: .motivation,
        createdAt: Date()
    ))
}

// MARK: - Activity View Controller Wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
