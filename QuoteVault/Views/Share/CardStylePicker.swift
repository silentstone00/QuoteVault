//
//  CardStylePicker.swift
//  QuoteVault
//
//  Picker for selecting card style
//

import SwiftUI

struct CardStylePicker: View {
    @Binding var selectedStyle: CardStyle
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(CardStyle.allCases, id: \.self) { style in
                    StyleOption(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        selectedStyle = style
                    }
                }
            }
            .padding(.horizontal)
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
        case .gradient:
            LinearGradient(
                colors: [Color.orange, Color.pink],
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
        style == .minimal ? .black : .white
    }
}

#Preview {
    CardStylePicker(selectedStyle: .constant(.gradient))
}
