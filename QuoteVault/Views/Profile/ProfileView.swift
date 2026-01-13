//
//  ProfileView.swift
//  QuoteVault
//
//  User profile view with edit capabilities
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar Section
                        VStack(spacing: 16) {
                            if let avatarUrl = viewModel.currentUser?.avatarUrl,
                               let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 120, height: 120)
                            }
                            
                            if isEditing {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Text("Change Photo")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                .onChange(of: selectedPhoto) { newValue in
                                    Task {
                                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                            try? await viewModel.authService.updateProfile(name: nil, avatarData: data)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Profile Info
                        VStack(spacing: 16) {
                            // Display Name
                            if isEditing {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Display Name")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Name", text: $editedName)
                                        .textFieldStyle(.roundedBorder)
                                        .padding(.horizontal)
                                }
                            } else {
                                VStack(spacing: 4) {
                                    Text(viewModel.currentUser?.displayName ?? "User")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Text(viewModel.currentUser?.email ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Edit/Save Button
                            if isEditing {
                                HStack(spacing: 12) {
                                    Button("Cancel") {
                                        isEditing = false
                                        editedName = viewModel.currentUser?.displayName ?? ""
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("Save") {
                                        Task {
                                            try? await viewModel.authService.updateProfile(
                                                name: editedName,
                                                avatarData: nil
                                            )
                                            isEditing = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            } else {
                                Button("Edit Profile") {
                                    editedName = viewModel.currentUser?.displayName ?? ""
                                    isEditing = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Account Section
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "envelope",
                                title: "Email",
                                value: viewModel.currentUser?.email ?? "",
                                showChevron: false
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            ProfileMenuItem(
                                icon: "calendar",
                                title: "Member Since",
                                value: formatDate(viewModel.currentUser?.createdAt),
                                showChevron: false
                            )
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Logout Button
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Spacer()
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
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Profile Menu Item

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let value: String
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
