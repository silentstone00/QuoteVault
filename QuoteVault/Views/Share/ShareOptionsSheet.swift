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
    @State private var selectedStyle: CardStyle = .gradient
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    @State private var showSaveSuccess = false
    @State private var errorMessage: String?
    
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
                        
                        if let image = generatedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .padding(.horizontal)
                        } else {
                            QuoteCardPreview(quote: quote, style: selectedStyle)
                                .frame(height: 300)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Style Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Style")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CardStylePicker(selectedStyle: $selectedStyle)
                            .onChange(of: selectedStyle) { _ in
                                generatedImage = nil // Reset preview when style changes
                            }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        // Generate Card Button
                        Button(action: {
                            Task {
                                await generateCard()
                            }
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "photo")
                                    Text("Generate Card")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal)
                        
                        // Share Text Button
                        Button(action: {
                            shareText()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share as Text")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Save to Photos Button
                        if generatedImage != nil {
                            Button(action: {
                                Task {
                                    await saveToPhotos()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save to Photos")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Success Message
                    if showSaveSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Saved to Photos!")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
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
        }
    }
    
    private func generateCard() async {
        isGenerating = true
        errorMessage = nil
        
        let image = await shareGenerator.generateQuoteCard(quote: quote, style: selectedStyle)
        generatedImage = image
        
        isGenerating = false
    }
    
    private func shareText() {
        let text = shareGenerator.generateShareText(quote: quote)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func saveToPhotos() async {
        guard let image = generatedImage else { return }
        
        errorMessage = nil
        showSaveSuccess = false
        
        do {
            try await shareGenerator.saveToPhotoLibrary(image: image)
            showSaveSuccess = true
            
            // Hide success message after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSaveSuccess = false
        } catch {
            errorMessage = error.localizedDescription
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
