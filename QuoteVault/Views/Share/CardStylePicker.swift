//
//  CardStylePicker.swift
//  QuoteVault
//
//  Picker for selecting card style
//

import SwiftUI
import PhotosUI

struct CardStylePicker: View {
    @Binding var selectedStyle: CardStyle
    @Binding var selectedPhoto: UIImage?
    @Binding var currentGradient: [Color]
    let onRandomGradient: () -> Void
    
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(CardStyle.allCases, id: \.self) { style in
                    if style == .photo {
                        PhotoStyleOption(
                            isSelected: selectedStyle == style,
                            selectedPhoto: selectedPhoto,
                            photoPickerItem: $photoPickerItem
                        ) {
                            selectedStyle = style
                        }
                    } else if style == .gradient {
                        GradientStyleOption(
                            isSelected: selectedStyle == style,
                            gradientColors: currentGradient,
                            onRandomTap: onRandomGradient
                        ) {
                            selectedStyle = style
                        }
                    } else {
                        StyleOption(
                            style: style,
                            isSelected: selectedStyle == style
                        ) {
                            selectedStyle = style
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: photoPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedPhoto = image
                    selectedStyle = .photo
                }
            }
        }
    }
}

struct PhotoStyleOption: View {
    let isSelected: Bool
    let selectedPhoto: UIImage?
    @Binding var photoPickerItem: PhotosPickerItem?
    let action: () -> Void
    
    var body: some View {
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            VStack(spacing: 8) {
                // Style Preview
                ZStack {
                    if let photo = selectedPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                    } else {
                        Color.gray.opacity(0.3)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                            Text("Add")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.gray)
                    }
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                
                // Style Name
                Text("Photo")
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GradientStyleOption: View {
    let isSelected: Bool
    let gradientColors: [Color]
    let onRandomTap: () -> Void
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Style Preview - Static gradient with random overlay
            Button(action: {
                action() // Select gradient style
                onRandomTap() // Generate random gradient
            }) {
                ZStack {
                    // Static gradient background for the option
                    LinearGradient(
                        colors: [Color.orange, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Random icon overlay
                    VStack(spacing: 4) {
                        Image(systemName: "shuffle")
                            .font(.title2)
                        Text("random")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
            }
            
            // Style Name
            Text("Gradient")
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .primary)
        }
    }
}

struct StyleOption: View {
    let style: CardStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Style Preview
                ZStack {
                    styleBackground
                    
                    VStack(spacing: 4) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.title2)
                        Text("Aa")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(textColor)
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                
                // Style Name
                Text(style.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
        }
    }
    
    @ViewBuilder
    private var styleBackground: some View {
        switch style {
        case .minimal:
            Color.white
        case .dark:
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gradient:
            LinearGradient(
                colors: [Color.orange, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .photo:
            Color.gray
        }
    }
    
    private var textColor: Color {
        style == .minimal ? .black : .white
    }
}

#Preview {
    CardStylePicker(
        selectedStyle: .constant(.gradient),
        selectedPhoto: .constant(nil),
        currentGradient: .constant([Color.orange, Color.pink]),
        onRandomGradient: {}
    )
}
