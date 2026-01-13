//
//  LoginView.swift
//  QuoteVault
//
//  Login screen with email/password authentication
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo/Title
                        VStack(spacing: 8) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("QuoteVault")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your daily dose of inspiration")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                        
                        // Login Form
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
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("Password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                
                                if let error = viewModel.passwordError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            // Forgot Password Button
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
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
                            
                            // Sign In Button
                            Button(action: {
                                Task {
                                    await viewModel.signIn()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isLoading || !viewModel.isSignInFormValid)
                            .opacity(viewModel.isSignInFormValid ? 1.0 : 0.6)
                            
                            // Sign Up Link
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.white)
                                
                                Button("Sign Up") {
                                    showSignUp = true
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
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

#Preview {
    LoginView()
}
