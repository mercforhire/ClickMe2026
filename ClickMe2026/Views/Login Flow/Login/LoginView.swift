//
//  LoginView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Q42. All rights reserved.
//

import AuthenticationServices
import SwiftUI

// MARK: - Login navigation routes

private enum LoginRoute: Hashable {
    case forgotPassword
}

// MARK: - Login Screen

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    // Navigation
    @State private var path: [LoginRoute] = []

    // UI-only animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    init(viewModel: LoginViewModel = LoginViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: LoginRoute.self) { route in
                    switch route {
                    case .forgotPassword:
                        LoginForgetPassView(
                            viewModel: LoginForgetPassViewModel(email: viewModel.email),
                            onBackToLogin: { path.removeLast() }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                    }
                }
        }
    }

    private var content: some View {
        ZStack {
            LinearGradient(
                colors: [LoginBrand.bgTop, LoginBrand.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    LoginHeaderSection()
                        .padding(.top, 56)
                        .padding(.bottom, 28)

                    formSection
                        .padding(.horizontal, 24)

                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            path.append(.forgotPassword)
                        }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(LoginBrand.green)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    LoginButton(isLoading: viewModel.isLoading) {
                        Task { await viewModel.attemptLogin() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    SignUpFooter()
                        .padding(.bottom, 32)
                }
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.55).delay(0.15)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .alert(
            "Something went wrong",
            isPresented: presenting(\.apiError),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    /// Binding that's `true` while the given optional property is non-nil, and
    /// clears it when the alert dismisses.
    private func presenting(_ keyPath: ReferenceWritableKeyPath<LoginViewModel, String?>) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { if !$0 { viewModel[keyPath: keyPath] = nil } }
        )
    }

    // MARK: Form

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ValidatedField(
                placeholder: "Email or Username",
                text: $viewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                error: viewModel.emailError
            )
            .onChange(of: viewModel.email) { _ in viewModel.emailDidChange() }

            ValidatedField(
                placeholder: "Password",
                text: $viewModel.password,
                icon: "lock",
                isSecure: true,
                error: viewModel.passwordError
            )
            .onChange(of: viewModel.password) { _ in viewModel.passwordDidChange() }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    LoginView()
        .preferredColorScheme(.dark)
}

#Preview("Email Error") {
    LoginView(viewModel: LoginViewModel(
        email: "john.doe@notanemail",
        password: "",
        emailError: "Invalid email format",
        didAttemptLogin: true
    ))
    .preferredColorScheme(.dark)
}

#Preview("Password Error") {
    LoginView(viewModel: LoginViewModel(
        email: "john.doe@example.com",
        password: "••••",
        passwordError: "Password must be at least 8 characters",
        didAttemptLogin: true
    ))
    .preferredColorScheme(.dark)
}

#Preview("Both Errors") {
    LoginView(viewModel: LoginViewModel(
        email: "john.doe@notanemail",
        password: "••••",
        emailError: "Invalid email format",
        passwordError: "Password must be at least 8 characters",
        didAttemptLogin: true
    ))
    .preferredColorScheme(.dark)
}
