//
//  CreateCollectionSheet.swift
//  QuoteVault
//
//  Sheet for creating a new collection
//

import SwiftUI

struct CreateCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collectionName = ""
    @State private var errorMessage: String?
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Collection Name", text: $collectionName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Text("Create a collection to organize your favorite quotes by theme, mood, or any category you like.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCollection()
                    }
                    .disabled(collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createCollection() {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Collection name cannot be empty"
            return
        }
        
        onCreate(trimmedName)
        dismiss()
    }
}

#Preview {
    CreateCollectionSheet { name in
        print("Created collection: \(name)")
    }
}
