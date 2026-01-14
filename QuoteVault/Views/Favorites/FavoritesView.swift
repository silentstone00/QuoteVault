//
//  FavoritesView.swift
//  QuoteVault
//
//  View showing all favorited quotes
//

import SwiftUI

struct FavoritesView: View {
    @Binding var isSelectionMode: Bool
    @ObservedObject private var viewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedQuotes: Set<UUID> = []
    @State private var showShareSheet = false
    @State private var toastMessage: String?
    @State private var showToast = false
    
    var body: some View {
        ZStack {
            Color.customBackground
                .ignoresSafeArea()
            
            if viewModel.favorites.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No Favorites Yet",
                    message: "Double tap any quote to add it to your favorites"
                )
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.favorites) { quote in
                            FavoriteQuoteRow(
                                quote: quote,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedQuotes.contains(quote.id),
                                onTap: {
                                    if isSelectionMode {
                                        toggleSelection(quote.id)
                                    }
                                }
                            )
                            .environmentObject(themeManager)
                            
                            Divider()
                                .padding(.leading, isSelectionMode ? 60 : 16)
                        }
                    }
                    .background(Color.customCard)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, selectedQuotes.isEmpty ? 16 : 116)
                }
                .background(
                    TwoFingerGestureView(isSelectionMode: $isSelectionMode)
                )
                .refreshable {
                    await viewModel.syncFromCloud()
                }
            }
            
            // Action Buttons Overlay
            if isSelectionMode && !selectedQuotes.isEmpty {
                VStack {
                    Spacer()
                    
                    if selectedQuotes.count == 1 {
                        // Show Copy, Share, Remove for single selection
                        HStack(spacing: 12) {
                            ActionButton(icon: "doc.on.doc", title: "Copy", color: .blue) {
                                copySelectedQuote()
                            }
                            
                            ActionButton(icon: "square.and.arrow.up", title: "Share", color: .green) {
                                showShareSheet = true
                            }
                            
                            ActionButton(icon: "trash", title: "Remove", color: .red) {
                                removeSelectedQuotes()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    } else {
                        // Show only Remove for multiple selections
                        ActionButton(icon: "trash", title: "Remove (\(selectedQuotes.count))", color: .red) {
                            removeSelectedQuotes()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            
            // Error Banner
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    ErrorBanner(message: error) {
                        viewModel.clearError()
                    }
                    .padding()
                }
            }
            
            // Toast at bottom
            if showToast, let message = toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarItems(trailing: navigationBarButtons)
        .onChange(of: isSelectionMode) { newValue in
            if !newValue {
                selectedQuotes.removeAll()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let quote = viewModel.favorites.first(where: { $0.id == selectedQuotes.first }) {
                ShareOptionsSheet(quote: quote)
            }
        }
    }
    
    // MARK: - Navigation Bar Buttons
    
    @ViewBuilder
    private var navigationBarButtons: some View {
        if isSelectionMode && !viewModel.favorites.isEmpty {
            Button(action: selectAll) {
                Text(allSelected ? "Deselect All" : "Select All")
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
            }
        }
    }
    
    private var allSelected: Bool {
        selectedQuotes.count == viewModel.favorites.count
    }
    
    // MARK: - Actions
    
    private func selectAll() {
        if allSelected {
            selectedQuotes.removeAll()
        } else {
            selectedQuotes = Set(viewModel.favorites.map { $0.id })
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedQuotes.contains(id) {
            selectedQuotes.remove(id)
        } else {
            selectedQuotes.insert(id)
        }
    }
    
    private func copySelectedQuote() {
        guard let quoteId = selectedQuotes.first,
              let quote = viewModel.favorites.first(where: { $0.id == quoteId }) else {
            return
        }
        
        let textToCopy = "\"\(quote.text)\" — \(quote.author)"
        UIPasteboard.general.string = textToCopy
        
        showToastMessage("Copied to clipboard")
        
        // Exit selection mode
        withAnimation {
            isSelectionMode = false
            selectedQuotes.removeAll()
        }
    }
    
    private func removeSelectedQuotes() {
        Task {
            for quoteId in selectedQuotes {
                if let quote = viewModel.favorites.first(where: { $0.id == quoteId }) {
                    await viewModel.toggleFavorite(quote: quote)
                }
            }
            
            await MainActor.run {
                showToastMessage("Removed from favorites")
                withAnimation {
                    isSelectionMode = false
                    selectedQuotes.removeAll()
                }
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showToast = false
            }
        }
    }
}

// MARK: - Favorite Quote Row

struct FavoriteQuoteRow: View {
    let quote: Quote
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox in selection mode
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? themeManager.accentColor : .gray)
                        .frame(width: 28)
                }
                
                // Quote content
                VStack(alignment: .leading, spacing: 8) {
                    Text("\"\(quote.text)\"")
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Text("— \(quote.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.customCard)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Two Finger Gesture View

struct TwoFingerGestureView: UIViewRepresentable {
    @Binding var isSelectionMode: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = context.coordinator
        panGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isSelectionMode: $isSelectionMode)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var isSelectionMode: Bool
        
        init(isSelectionMode: Binding<Bool>) {
            _isSelectionMode = isSelectionMode
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began && !isSelectionMode {
                withAnimation {
                    isSelectionMode = true
                }
            }
        }
        
        // Allow simultaneous gesture recognition
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        // Don't block other touches
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            return true
        }
    }
}

#Preview {
    FavoritesView(isSelectionMode: .constant(false))
        .environmentObject(ThemeManager())
}
