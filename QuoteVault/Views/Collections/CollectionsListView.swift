//
//  CollectionsListView.swift
//  QuoteVault
//
//  View showing all user collections
//

import SwiftUI

struct CollectionsListView: View {
    @ObservedObject private var viewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Color.customBackground
                .ignoresSafeArea()
            
            if viewModel.collections.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No Collections Yet",
                    message: "Hold any quote to add it to your collection"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(viewModel.collections) { collection in
                            NavigationLink(destination: CollectionDetailView(collection: collection)
                                .environmentObject(themeManager)) {
                                CollectionCard(collection: collection)
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await viewModel.syncFromCloud()
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
        }
        .sheet(isPresented: $viewModel.showCreateCollection) {
            CreateCollectionSheet { name in
                Task {
                    await viewModel.createCollection(name: name)
                }
            }
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: QuoteCollection
    @ObservedObject private var viewModel = CollectionViewModel.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var quoteCount: Int = 0
    @State private var loadTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 8) {
            // Folder icon
            Image(systemName: "folder.fill")
                .font(.system(size: 40))
                .foregroundColor(themeManager.accentColor)
            
            // Collection name
            Text(collection.name)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Quote count
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(quoteCount) quotes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 14)
        .background(Color.customCard)
        .cornerRadius(16)
        .aspectRatio(0.95, contentMode: .fit)
        .onAppear {
            loadQuoteCount()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }
    
    private func loadQuoteCount() {
        loadTask?.cancel()
        loadTask = Task {
            let count = await viewModel.getQuoteCount(for: collection.id)
            if !Task.isCancelled {
                await MainActor.run {
                    quoteCount = count
                }
            }
        }
    }
}

#Preview {
    CollectionsListView()
}
