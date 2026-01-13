//
//  ForgotPasswordView.swift
//  QuoteVault
//
//  Password reset screen
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.5), Color.cyan.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Reset Password")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Enter your email to receive a password reset link")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 60)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            
                            if let error = viewModel.emailError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        // Success/Error Message
                        if let message = viewModel.errorMessage {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(showSuccessMessage ? .green : .red)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                        }
                        
                        // Reset Button
                        Button(action: {
                            Task {
                                await viewModel.resetPassword()
                                if viewModel.errorMessage != nil {
                                    showSuccessMessage = true
                                    // Auto dismiss after 2 seconds on success
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        dismiss()
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                } else {
                                    Text("Send Reset Link")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoading || !viewModel.isForgotPasswordFormValid)
                        .opacity(viewModel.isForgotPasswordFormValid ? 1.0 : 0.6)
                        
                        // Back to login
                        Button("Back to Login") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
