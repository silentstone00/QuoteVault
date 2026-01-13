//
//  SignUpView.swift
//  QuoteVault
//
//  Sign up screen with registration form
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text("Create Account")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Join QuoteVault today")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Sign Up Form
                        VStack(spacing: 16) {
                            // Display Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Display Name", text: $viewModel.displayName)
                                    .textContentType(.name)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                            
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
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("Password", text: $viewModel.password)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                
                                if let error = viewModel.passwordError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 4)
                                } else {
                                    Text("Must be at least 8 characters")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                
                                if let error = viewModel.confirmPasswordError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            // Error Message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                            }
                            
                            // Sign Up Button
                            Button(action: {
                                Task {
                                    await viewModel.signUp()
                                    if viewModel.isAuthenticated {
                                        dismiss()
                                    }
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                    } else {
                                        Text("Sign Up")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.purple)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isLoading || !viewModel.isSignUpFormValid)
                            .opacity(viewModel.isSignUpFormValid ? 1.0 : 0.6)
                            
                            // Already have account link
                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.white)
                                
                                Button("Sign In") {
                                    dismiss()
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    }
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
    SignUpView()
}
