//
//  CategoryFilterView.swift
//  QuoteVault
//
//  Horizontal scrolling category filter chips
//

import SwiftUI

struct CategoryFilterView: View {
    @Binding var selectedCategory: QuoteCategory?
    let onCategorySelected: (QuoteCategory?) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Categories chip
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                    onCategorySelected(nil)
                }
                
                // Individual category chips
                ForEach(QuoteCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        color: categoryColor(for: category)
                    ) {
                        selectedCategory = category
                        onCategorySelected(category)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func categoryColor(for category: QuoteCategory) -> Color {
        switch category {
        case .motivation:
            return .orange
        case .love:
            return .pink
        case .success:
            return .green
        case .wisdom:
            return .purple
        case .humor:
            return .blue
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    CategoryFilterView(
        selectedCategory: .constant(.motivation),
        onCategorySelected: { _ in }
    )
}
