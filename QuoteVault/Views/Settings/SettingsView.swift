//
//  SettingsView.swift
//  QuoteVault
//
//  Settings screen for theme and preferences
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section {
                    // Color Scheme Picker
                    Picker("Appearance", selection: $viewModel.colorScheme) {
                        Text("System").tag(nil as ColorScheme?)
                        Text("Light").tag(ColorScheme.light as ColorScheme?)
                        Text("Dark").tag(ColorScheme.dark as ColorScheme?)
                    }
                    .onChange(of: viewModel.colorScheme) { newValue in
                        viewModel.updateColorScheme(newValue)
                    }
                    
                    // Accent Color Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accent Color")
                            .font(.subheadline)
                        
                        HStack(spacing: 16) {
                            ForEach(AccentColorOption.allCases, id: \.self) { option in
                                AccentColorSwatch(
                                    color: option,
                                    isSelected: viewModel.accentColor == option
                                ) {
                                    viewModel.updateAccentColor(option)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Appearance")
                }
                
                // Typography Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Font Size")
                                .font(.subheadline)
                            Spacer()
                            Text(viewModel.fontSize.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Font Size Slider
                        HStack(spacing: 12) {
                            Text("A")
                                .font(.caption)
                            
                            Slider(
                                value: Binding(
                                    get: {
                                        Double(FontSizeOption.allCases.firstIndex(of: viewModel.fontSize) ?? 1)
                                    },
                                    set: { newValue in
                                        let index = Int(newValue)
                                        if index < FontSizeOption.allCases.count {
                                            viewModel.updateFontSize(FontSizeOption.allCases[index])
                                        }
                                    }
                                ),
                                in: 0...Double(FontSizeOption.allCases.count - 1),
                                step: 1
                            )
                            .accentColor(themeManager.accentColor)
                            
                            Text("A")
                                .font(.title2)
                        }
                        
                        // Preview Text
                        Text("The only way to do great work is to love what you do.")
                            .font(.system(size: viewModel.fontSize.fontSize))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Typography")
                }
                
                // Notifications Section
                Section {
                    Toggle("Daily Quote Notification", isOn: Binding(
                        get: { viewModel.notificationsEnabled },
                        set: { newValue in
                            Task {
                                await viewModel.toggleNotifications(newValue)
                            }
                        }
                    ))
                    .tint(themeManager.accentColor)
                    
                    if viewModel.notificationsEnabled {
                        DatePicker(
                            "Notification Time",
                            selection: Binding(
                                get: { viewModel.notificationTime },
                                set: { newValue in
                                    Task {
                                        await viewModel.updateNotificationTime(newValue)
                                    }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .accentColor(themeManager.accentColor)
                        
                        Text("Receive a daily quote notification at your preferred time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if !viewModel.notificationsEnabled {
                        Text("Enable notifications to receive a daily quote at your preferred time")
                    }
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

// MARK: - Accent Color Swatch

struct AccentColorSwatch: View {
    let color: AccentColorOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
