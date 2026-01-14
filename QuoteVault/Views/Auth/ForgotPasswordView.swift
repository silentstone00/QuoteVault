//
//  ForgotPasswordView.swift
//  QuoteVault
//
//  Minimal password reset screen
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSuccessMessage = false
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F3F4F6"))
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                        }
                        .padding(.bottom, 4)
                        
                        Text("Reset password")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        
                        Text("Enter your email to receive a reset link")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(hex: "6B7280"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 40)
                    
                    // Form
                    VStack(spacing: 24) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            
                            TextField("", text: $viewModel.email, prompt: Text("Enter your email").foregroundColor(Color(hex: "9CA3AF")))
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .focused($isEmailFocused)
                                .foregroundColor(Color(hex: "1A1A1A"))
                                .padding(14)
                                .background(Color(hex: "F9FAFB"))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            isEmailFocused ? Color(hex: "1A1A1A") :
                                            viewModel.emailError != nil ? Color(hex: "EF4444") : Color(hex: "E5E7EB"),
                                            lineWidth: isEmailFocused ? 1.5 : 1
                                        )
                                )
                            
                            if let error = viewModel.emailError {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text(error)
                                        .font(.system(size: 13, weight: .regular))
                                }
                                .foregroundColor(Color(hex: "EF4444"))
                            }
                        }
                        
                        // Success/Error Message
                        if let message = viewModel.errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: showSuccessMessage ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                Text(message)
                                    .font(.system(size: 14, weight: .regular))
                            }
                            .foregroundColor(showSuccessMessage ? Color(hex: "059669") : Color(hex: "DC2626"))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(showSuccessMessage ? Color(hex: "D1FAE5") : Color(hex: "FEE2E2"))
                            .cornerRadius(8)
                        }
                        
                        // Reset Button
                        Button {
                            isEmailFocused = false
                            Task {
                                await viewModel.resetPassword()
                                if viewModel.errorMessage != nil {
                                    showSuccessMessage = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        dismiss()
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.85)
                                }
                                Text(viewModel.isLoading ? "Sending link..." : "Send reset link")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(viewModel.isForgotPasswordFormValid ? Color(hex: "1A1A1A") : Color(hex: "E5E7EB"))
                            .foregroundColor(viewModel.isForgotPasswordFormValid ? .white : Color(hex: "9CA3AF"))
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading || !viewModel.isForgotPasswordFormValid)
                        
                        // Back to login
                        Button {
                            dismiss()
                        } label: {
                            Text("Back to sign in")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .regular))
                        }
                        .foregroundColor(Color(hex: "1A1A1A"))
                    }
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
