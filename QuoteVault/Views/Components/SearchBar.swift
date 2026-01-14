//
//  SearchBar.swift
//  QuoteVault
//
//  Search bar component for quote search
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @EnvironmentObject var themeManager: ThemeManager
    var onFilterTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField("Search quotes or authors...", text: $text)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .foregroundColor(.primary)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.customCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused ? themeManager.accentColor : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
            .cornerRadius(14)
            
            // Filter button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onFilterTap()
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    SearchBar(text: .constant(""), onFilterTap: {})
        .environmentObject(ThemeManager())
        .padding()
}
