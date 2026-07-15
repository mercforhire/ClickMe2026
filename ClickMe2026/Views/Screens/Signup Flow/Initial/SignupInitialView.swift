//
//  SignupInitialView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Create Account Screen

struct SignupInitialView: View {

    @StateObject private var viewModel: SignupInitialViewModel

    // UI-only animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 18

    var onContinue: () -> Void

    // MARK: Inits

    init(
        viewModel: SignupInitialViewModel = SignupInitialViewModel(),
        onContinue: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContinue = onContinue
    }

    /// Runtime init — wires `POST /auth/signup` via `UserManager` and mirrors
    /// credentials onto the shared accumulator.
    init(
        accumulator: SignupAccumulator,
        userManager: UserManager = .shared,
        onContinue: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: SignupInitialViewModel(
                accumulator: accumulator,
                userManager: userManager
            ),
            onContinue: onContinue
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SignupBrand.bgTop, SignupBrand.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle radial highlight top-centre
            RadialGradient(
                colors: [SignupBrand.green.opacity(0.12), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    VStack(spacing: 10) {
                        Text("Create Account")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Start your journey with us.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.50))
                    }
                    .padding(.bottom, 36)

                    formSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    SignupContinueButton(isLoading: viewModel.isLoading) {
                        viewModel.attemptContinue()
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 48)
                }
            }
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .onChange(of: viewModel.isComplete) { _, newValue in
            if newValue { onContinue() }
        }
        .alert(
            "Couldn't create account",
            isPresented: Binding(
                get: { viewModel.apiError != nil },
                set: { if !$0 { viewModel.apiError = nil } }
            ),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) { viewModel.apiError = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: Form

    private var formSection: some View {
        VStack(spacing: 0) {
            SignupValidatedField(
                placeholder: "Username",
                text: $viewModel.username,
                error: viewModel.usernameError
            )
            .onChange(of: viewModel.username) { viewModel.usernameDidChange() }

            SignupValidatedField(
                placeholder: "Email",
                text: $viewModel.email,
                error: viewModel.emailError,
                keyboardType: .emailAddress
            )
            .onChange(of: viewModel.email) { viewModel.emailDidChange() }

            SignupValidatedField(
                placeholder: "Password",
                text: $viewModel.password,
                error: viewModel.passwordError,
                isSecure: true
            )
            .onChange(of: viewModel.password) { viewModel.passwordDidChange() }
        }
    }
}

// MARK: - Preview helpers

private enum PreviewRoute: Hashable {
    case signupInitial
    case basicInfo
}

/// Wraps the initial signup screen in a NavigationStack with a dummy "Login"
/// parent already pushed, so the system back chevron renders in the canvas
/// and tapping Continue still pushes to the basic-info destination.
private struct PreviewInitial: View {
    let viewModel: SignupInitialViewModel
    @State private var path: [PreviewRoute]

    init(viewModel: SignupInitialViewModel) {
        self.viewModel = viewModel
        _path = State(initialValue: [.signupInitial])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Sign in")
                NavigationLink("Create account", value: PreviewRoute.signupInitial)
            }
            .navigationTitle("Login")
            .navigationDestination(for: PreviewRoute.self) { route in
                switch route {
                case .signupInitial:
                    SignupInitialView(
                        viewModel: viewModel,
                        onContinue: { path.append(.basicInfo) }
                    )
                case .basicInfo:
                    SignupBasicInfoView()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    PreviewInitial(viewModel: SignupInitialViewModel())
        .preferredColorScheme(.dark)
}

#Preview("All Errors") {
    PreviewInitial(viewModel: SignupInitialViewModel(
        username: "ab",
        email: "notanemail",
        password: "123",
        usernameError: "Username must be at least 3 characters",
        emailError: "Invalid email format",
        passwordError: "Password must be at least 8 characters",
        didAttemptContinue: true
    ))
    .preferredColorScheme(.dark)
}

#Preview("Username Error") {
    PreviewInitial(viewModel: SignupInitialViewModel(
        username: "",
        usernameError: "Username is required",
        didAttemptContinue: true
    ))
    .preferredColorScheme(.dark)
}

#Preview("Valid — Ready to Continue") {
    PreviewInitial(viewModel: SignupInitialViewModel(
        username: "johndoe",
        email: "john@example.com",
        password: "Secure123!"
    ))
    .preferredColorScheme(.dark)
}
