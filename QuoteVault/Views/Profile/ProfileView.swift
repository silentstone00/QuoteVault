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
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showLogoutAlert = false
    @State private var colorScheme: ColorScheme?
    @State private var accentColor: AccentColorOption = .blue
    @State private var fontSize: FontSizeOption = .medium
    @State private var notificationsEnabled = false
    @State private var notificationTime = Date()
    private let notificationScheduler = NotificationScheduler()
    private let quoteService = QuoteService()
    
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
                                            await viewModel.updateProfile(name: nil, avatarData: data)
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
                                            await viewModel.updateProfile(
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
                        
                        // Settings Section - Appearance
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Appearance")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // Color Scheme
                                HStack {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 28)
                                    
                                    Text("Theme")
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $colorScheme) {
                                        Text("System").tag(nil as ColorScheme?)
                                        Text("Light").tag(ColorScheme.light as ColorScheme?)
                                        Text("Dark").tag(ColorScheme.dark as ColorScheme?)
                                    }
                                    .pickerStyle(.menu)
                                    .onChange(of: colorScheme) { newValue in
                                        themeManager.setColorScheme(newValue)
                                    }
                                }
                                .padding()
                                
                                Divider()
                                    .padding(.leading, 52)
                                
                                // Accent Color
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "paintpalette")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                            .frame(width: 28)
                                        
                                        Text("Accent Color")
                                            .font(.body)
                                    }
                                    
                                    HStack(spacing: 16) {
                                        ForEach(AccentColorOption.allCases, id: \.self) { option in
                                            AccentColorSwatch(
                                                color: option,
                                                isSelected: accentColor == option
                                            ) {
                                                accentColor = option
                                                themeManager.setAccentColor(option)
                                            }
                                        }
                                    }
                                    .padding(.leading, 44)
                                }
                                .padding()
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Settings Section - Typography
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Typography")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "textformat.size")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 28)
                                    
                                    Text("Font Size")
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Text(fontSize.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                
                                // Font Size Slider
                                HStack(spacing: 12) {
                                    Text("A")
                                        .font(.caption)
                                    
                                    Slider(
                                        value: Binding(
                                            get: {
                                                Double(FontSizeOption.allCases.firstIndex(of: fontSize) ?? 1)
                                            },
                                            set: { newValue in
                                                let index = Int(newValue)
                                                if index < FontSizeOption.allCases.count {
                                                    fontSize = FontSizeOption.allCases[index]
                                                    themeManager.setFontSize(fontSize)
                                                }
                                            }
                                        ),
                                        in: 0...Double(FontSizeOption.allCases.count - 1),
                                        step: 1
                                    )
                                    .tint(themeManager.accentColor)
                                    
                                    Text("A")
                                        .font(.title2)
                                }
                                .padding(.horizontal)
                                
                                // Preview Text
                                Text("The only way to do great work is to love what you do.")
                                    .font(.system(size: fontSize.fontSize))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Settings Section - Notifications
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 28)
                                    
                                    Text("Daily Quote")
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { notificationsEnabled },
                                        set: { newValue in
                                            Task {
                                                await toggleNotifications(newValue)
                                            }
                                        }
                                    ))
                                    .tint(themeManager.accentColor)
                                }
                                .padding()
                                
                                if notificationsEnabled {
                                    Divider()
                                        .padding(.leading, 52)
                                    
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                            .frame(width: 28)
                                        
                                        DatePicker(
                                            "Time",
                                            selection: Binding(
                                                get: { notificationTime },
                                                set: { newValue in
                                                    Task {
                                                        await updateNotificationTime(newValue)
                                                    }
                                                }
                                            ),
                                            displayedComponents: .hourAndMinute
                                        )
                                        .tint(themeManager.accentColor)
                                    }
                                    .padding()
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 28)
                                    
                                    Text("Version")
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                
                                Divider()
                                    .padding(.leading, 52)
                                
                                Link(destination: URL(string: "https://example.com/privacy")!) {
                                    HStack {
                                        Image(systemName: "hand.raised")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                            .frame(width: 28)
                                        
                                        Text("Privacy Policy")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                                
                                Divider()
                                    .padding(.leading, 52)
                                
                                Link(destination: URL(string: "https://example.com/terms")!) {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                            .frame(width: 28)
                                        
                                        Text("Terms of Service")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
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
            .task {
                // Load theme settings
                colorScheme = themeManager.colorScheme
                accentColor = themeManager.theme.accentColor
                fontSize = themeManager.theme.fontSize
                
                // Load notification settings
                await loadNotificationSettings()
            }
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
    
    // MARK: - Notification Methods
    
    private func loadNotificationSettings() async {
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: "notificationsEnabled")
        
        if let savedTime = defaults.object(forKey: "notificationTime") as? Date {
            notificationTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            notificationTime = Calendar.current.date(from: components) ?? Date()
        }
        
        let isAuthorized = await notificationScheduler.isAuthorized()
        notificationsEnabled = enabled && isAuthorized
    }
    
    private func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            do {
                let granted = try await notificationScheduler.requestPermission()
                
                if granted {
                    let quote = try await quoteService.getQuoteOfTheDay()
                    let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
                    try await notificationScheduler.scheduleDaily(at: timeComponents, quote: quote)
                    
                    notificationsEnabled = true
                    saveNotificationSettings()
                } else {
                    notificationsEnabled = false
                }
            } catch {
                notificationsEnabled = false
            }
        } else {
            await notificationScheduler.cancelAllNotifications()
            notificationsEnabled = false
            saveNotificationSettings()
        }
    }
    
    private func updateNotificationTime(_ time: Date) async {
        notificationTime = time
        
        if notificationsEnabled {
            do {
                let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
                try await notificationScheduler.updateNotificationTime(timeComponents)
                saveNotificationSettings()
            } catch {
                print("Failed to update notification time")
            }
        } else {
            saveNotificationSettings()
        }
    }
    
    private func saveNotificationSettings() {
        let defaults = UserDefaults.standard
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(notificationTime, forKey: "notificationTime")
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
