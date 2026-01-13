//
//  AddToCollectionSheet.swift
//  QuoteVault
//
//  Sheet for adding a quote to a collection
//

import SwiftUI

struct AddToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let quote: Quote
    let collections: [QuoteCollection]
    let onAdd: (UUID) -> Void
    
    var body: some View {
        NavigationView {
            List {
                if collections.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("No Collections")
                                .font(.headline)
                            
                            Text("Create a collection first to add quotes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                } else {
                    Section {
                        ForEach(collections) { collection in
                            Button(action: {
                                onAdd(collection.id)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(collection.name)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(collection.quoteCount ?? 0) quotes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } header: {
                        Text("Select Collection")
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddToCollectionSheet(
        quote: Quote(
            id: UUID(),
            text: "Sample quote",
            author: "Author",
            category: .motivation,
            createdAt: Date()
        ),
        collections: [
            QuoteCollection(id: UUID(), name: "Favorites", userId: UUID(), createdAt: Date(), quoteCount: 5),
            QuoteCollection(id: UUID(), name: "Inspiration", userId: UUID(), createdAt: Date(), quoteCount: 3)
        ],
        onAdd: { _ in }
    )
}
