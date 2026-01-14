//
//  SignUpView.swift
//  QuoteVault
//
//  Minimal sign up screen with refined UX
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case displayName, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1A1A1A"))
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: "quote.closing")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 4)
                            
                            Text("Create account")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            
                            Text("Join us to save your favorite quotes")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                        
                        // Sign Up Form
                        VStack(spacing: 24) {
                            // Display Name Field
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Display name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                
                                TextField("", text: $viewModel.displayName, prompt: Text("Enter your name").foregroundColor(Color(hex: "9CA3AF")))
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .displayName)
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                    .padding(14)
                                    .background(Color(hex: "F9FAFB"))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                focusedField == .displayName ? Color(hex: "1A1A1A") : Color(hex: "E5E7EB"),
                                                lineWidth: focusedField == .displayName ? 1.5 : 1
                                            )
                                    )
                            }
                            
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
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                
                                ZStack(alignment: .trailing) {
                                    Group {
                                        if viewModel.isPasswordVisible {
                                            TextField("", text: $viewModel.password, prompt: Text("Minimum 8 characters").foregroundColor(Color(hex: "9CA3AF")))
                                                .textContentType(.newPassword)
                                                .foregroundColor(Color(hex: "1A1A1A"))
                                        } else {
                                            SecureField("", text: $viewModel.password, prompt: Text("Minimum 8 characters").foregroundColor(Color(hex: "9CA3AF")))
                                                .textContentType(.newPassword)
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
                                } else if !viewModel.password.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: viewModel.password.count >= 8 ? "checkmark.circle.fill" : "info.circle.fill")
                                            .font(.system(size: 12))
                                        Text(viewModel.password.count >= 8 ? "Strong password" : "At least 8 characters")
                                            .font(.system(size: 13, weight: .regular))
                                    }
                                    .foregroundColor(viewModel.password.count >= 8 ? Color(hex: "10B981") : Color(hex: "6B7280"))
                                }
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Confirm password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                
                                ZStack(alignment: .trailing) {
                                    Group {
                                        if viewModel.isConfirmPasswordVisible {
                                            TextField("", text: $viewModel.confirmPassword, prompt: Text("Re-enter password").foregroundColor(Color(hex: "9CA3AF")))
                                                .textContentType(.newPassword)
                                                .foregroundColor(Color(hex: "1A1A1A"))
                                        } else {
                                            SecureField("", text: $viewModel.confirmPassword, prompt: Text("Re-enter password").foregroundColor(Color(hex: "9CA3AF")))
                                                .textContentType(.newPassword)
                                                .foregroundColor(Color(hex: "1A1A1A"))
                                        }
                                    }
                                    .focused($focusedField, equals: .confirmPassword)
                                    .padding(14)
                                    .padding(.trailing, 40)
                                    .background(Color(hex: "F9FAFB"))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                focusedField == .confirmPassword ? Color(hex: "1A1A1A") :
                                                viewModel.confirmPasswordError != nil ? Color(hex: "EF4444") : Color(hex: "E5E7EB"),
                                                lineWidth: focusedField == .confirmPassword ? 1.5 : 1
                                            )
                                    )
                                    
                                    Button {
                                        viewModel.isConfirmPasswordVisible.toggle()
                                    } label: {
                                        Image(systemName: viewModel.isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "6B7280"))
                                            .frame(width: 40, height: 40)
                                    }
                                    .padding(.trailing, 6)
                                }
                                
                                if let error = viewModel.confirmPasswordError {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 12))
                                        Text(error)
                                            .font(.system(size: 13, weight: .regular))
                                    }
                                    .foregroundColor(Color(hex: "EF4444"))
                                } else if !viewModel.confirmPassword.isEmpty && viewModel.password == viewModel.confirmPassword {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                        Text("Passwords match")
                                            .font(.system(size: 13, weight: .regular))
                                    }
                                    .foregroundColor(Color(hex: "10B981"))
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
                            
                            // Sign Up Button
                            Button {
                                focusedField = nil
                                Task {
                                    await viewModel.signUp()
                                    if viewModel.isAuthenticated {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.85)
                                    }
                                    Text(viewModel.isLoading ? "Creating account..." : "Create account")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(viewModel.isSignUpFormValid ? Color(hex: "1A1A1A") : Color(hex: "E5E7EB"))
                                .foregroundColor(viewModel.isSignUpFormValid ? .white : Color(hex: "9CA3AF"))
                                .cornerRadius(8)
                            }
                            .disabled(viewModel.isLoading || !viewModel.isSignUpFormValid)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        
                        // Sign In Link
                        HStack(spacing: 6) {
                            Text("Already have an account?")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "6B7280"))
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Sign in")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                            }
                        }
                        .padding(.top, 24)
                        
                        Spacer(minLength: 30)
                    }
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
    SignUpView()
}
