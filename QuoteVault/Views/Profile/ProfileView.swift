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
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    appearanceSection
                    typographySection
                    notificationsSection
                    logoutButton
                    Spacer()
                }
            }
            .background(Color.customBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.customBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay(errorBanner)
            .task {
                colorScheme = themeManager.colorScheme
                accentColor = themeManager.theme.accentColor
                fontSize = themeManager.theme.fontSize
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
    
    // MARK: - View Components
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            avatarView
            
            if isEditing {
                photoPickerButton
            }
            
            if isEditing {
                nameEditField
            } else {
                userInfoDisplay
            }
            
            editSaveButtons
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.customCard)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var avatarView: some View {
        Group {
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
        }
    }
    
    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Text("Change Photo")
                .font(.subheadline)
                .foregroundColor(themeManager.accentColor)
        }
        .onChange(of: selectedPhoto) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await viewModel.updateProfile(name: nil, avatarData: data)
                }
            }
        }
    }
    
    private var nameEditField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Name", text: $editedName)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }
    
    private var userInfoDisplay: some View {
        VStack(spacing: 8) {
            Text(viewModel.currentUser?.displayName ?? "User")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            memberSinceBadge
        }
    }
    
    private var memberSinceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.caption)
            Text("Member since \(formatDate(viewModel.currentUser?.createdAt))")
                .font(.caption)
        }
        .foregroundColor(.secondary)
        .padding(.top, 4)
    }
    
    private var editSaveButtons: some View {
        Group {
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
                    .tint(themeManager.accentColor)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                Button("Edit Profile") {
                    editedName = viewModel.currentUser?.displayName ?? ""
                    isEditing = true
                }
                .buttonStyle(.bordered)
                .tint(themeManager.accentColor)
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                darkModeToggle
                
                Divider()
                    .padding(.leading, 52)
                
                accentColorPicker
            }
            .background(Color.customCard)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var darkModeToggle: some View {
        HStack {
            Image(systemName: "moon.fill")
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 28)
            
            Text("Dark Mode")
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: darkModeBinding)
                .tint(themeManager.accentColor)
        }
        .padding()
    }
    
    private var darkModeBinding: Binding<Bool> {
        Binding(
            get: {
                if let scheme = colorScheme {
                    return scheme == .dark
                }
                return UITraitCollection.current.userInterfaceStyle == .dark
            },
            set: { isDark in
                colorScheme = isDark ? .dark : .light
                themeManager.setColorScheme(colorScheme)
            }
        )
    }
    
    private var accentColorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintpalette")
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
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
                        withAnimation(.easeInOut(duration: 0.2)) {
                            accentColor = option
                            themeManager.setAccentColor(option)
                        }
                    }
                }
            }
            .padding(.leading, 44)
        }
        .padding()
    }
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Typography")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                fontSizeHeader
                fontSizeSlider
                previewText
            }
            .padding(.vertical)
            .background(Color.customCard)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var fontSizeHeader: some View {
        HStack {
            Image(systemName: "textformat.size")
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 28)
            
            Text("Font Size")
                .font(.body)
            
            Spacer()
            
            Text(fontSize.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var fontSizeSlider: some View {
        HStack(spacing: 12) {
            Text("A")
                .font(.caption)
            
            Slider(value: fontSizeBinding, in: 0...Double(FontSizeOption.allCases.count - 1), step: 1)
                .tint(themeManager.accentColor)
            
            Text("A")
                .font(.title2)
        }
        .padding(.horizontal)
    }
    
    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: {
                Double(FontSizeOption.allCases.firstIndex(of: fontSize) ?? 1)
            },
            set: { newValue in
                let index = Int(round(newValue))
                if index < FontSizeOption.allCases.count {
                    fontSize = FontSizeOption.allCases[index]
                    themeManager.setFontSize(fontSize)
                }
            }
        )
    }
    
    private var previewText: some View {
        Text("The only way to do great work is to love what you do.")
            .font(.system(size: themeManager.quoteFontSize))
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                notificationToggle
                
                if notificationsEnabled {
                    Divider()
                        .padding(.leading, 52)
                    
                    notificationTimePicker
                }
            }
            .background(Color.customCard)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var notificationToggle: some View {
        HStack {
            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 28)
            
            Text("Daily Quote")
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: notificationBinding)
                .tint(themeManager.accentColor)
        }
        .padding()
    }
    
    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { notificationsEnabled },
            set: { newValue in
                Task {
                    await toggleNotifications(newValue)
                }
            }
        )
    }
    
    private var notificationTimePicker: some View {
        HStack {
            Image(systemName: "clock")
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 28)
            
            DatePicker("Time", selection: notificationTimeBinding, displayedComponents: .hourAndMinute)
                .tint(themeManager.accentColor)
        }
        .padding()
    }
    
    private var notificationTimeBinding: Binding<Date> {
        Binding(
            get: { notificationTime },
            set: { newValue in
                Task {
                    await updateNotificationTime(newValue)
                }
            }
        )
    }
    
    private var logoutButton: some View {
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
    }
    
    private var errorBanner: some View {
        Group {
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
    }
    
    // MARK: - Helper Methods
    
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
    var accentColor: Color = .blue
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(accentColor)
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
