//
//  LoginView.swift
//  QuoteVault
//
//  Minimal login screen with refined UX
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Logo and Welcome
                        VStack(spacing: 16) {
                            // Quote mark icon
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1A1A1A"))
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 4)
                            
                            Text("Welcome back")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            
                            Text("Sign in to access your quotes")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                        .padding(.top, 80)
                        .padding(.bottom, 48)
                        
                        // Login Form
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
                                    .focused($focusedField, equals: .email)
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                    .padding(14)
                                    .background(Color(hex: "F9FAFB"))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                focusedField == .email ? Color(hex: "1A1A1A") :
                                                viewModel.emailError != nil ? Color(hex: "EF4444") : Color(hex: "E5E7EB"),
                                                lineWidth: focusedField == .email ? 1.5 : 1
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
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "1A1A1A"))
                                    
                                    Spacer()
                                    
                                    Button {
                                        showForgotPassword = true
                                    } label: {
                                        Text("Forgot?")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(hex: "6B7280"))
                                    }
                                }
                                
                                ZStack(alignment: .trailing) {
                                    Group {
                                        if viewModel.isPasswordVisible {
                                            TextField("", text: $viewModel.password, prompt: Text("Enter your password").foregroundColor(Color(hex: "9CA3AF")))
                                                .textContentType(.password)
                                                .foregroundColor(Color(hex: "1A1A1A"))
                                        } else {
                                            SecureField("", text: $viewModel.password, prompt: Text("Enter your password").foregroundColor(Color(hex: "9CA3AF")))
                                                .textContentType(.password)
                                                .foregroundColor(Color(hex: "1A1A1A"))
                                        }
                                    }
                                    .focused($focusedField, equals: .password)
                                    .padding(14)
                                    .padding(.trailing, 40)
                                    .background(Color(hex: "F9FAFB"))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                focusedField == .password ? Color(hex: "1A1A1A") :
                                                viewModel.passwordError != nil ? Color(hex: "EF4444") : Color(hex: "E5E7EB"),
                                                lineWidth: focusedField == .password ? 1.5 : 1
                                            )
                                    )
                                    
                                    Button {
                                        viewModel.isPasswordVisible.toggle()
                                    } label: {
                                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "6B7280"))
                                            .frame(width: 40, height: 40)
                                    }
                                    .padding(.trailing, 6)
                                }
                                
                                if let error = viewModel.passwordError {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 12))
                                        Text(error)
                                            .font(.system(size: 13, weight: .regular))
                                    }
                                    .foregroundColor(Color(hex: "EF4444"))
                                }
                            }
                            
                            // Error Message
                            if let error = viewModel.errorMessage {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 14))
                                    Text(error)
                                        .font(.system(size: 14, weight: .regular))
                                }
                                .foregroundColor(Color(hex: "DC2626"))
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: "FEE2E2"))
                                .cornerRadius(8)
                            }
                            
                            // Sign In Button
                            Button {
                                focusedField = nil
                                Task {
                                    await viewModel.signIn()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.85)
                                    }
                                    Text(viewModel.isLoading ? "Signing in..." : "Sign in")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(viewModel.isSignInFormValid ? Color(hex: "1A1A1A") : Color(hex: "E5E7EB"))
                                .foregroundColor(viewModel.isSignInFormValid ? .white : Color(hex: "9CA3AF"))
                                .cornerRadius(8)
                            }
                            .disabled(viewModel.isLoading || !viewModel.isSignInFormValid)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        
                        // Sign Up Link
                        HStack(spacing: 6) {
                            Text("Don't have an account?")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "6B7280"))
                            
                            Button {
                                showSignUp = true
                            } label: {
                                Text("Sign up")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                            }
                        }
                        .padding(.top, 32)
                        
                        Spacer(minLength: 40)
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
