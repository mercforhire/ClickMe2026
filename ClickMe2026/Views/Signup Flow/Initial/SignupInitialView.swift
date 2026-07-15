//
//  SignupInitialView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Create Account Screen (Step 1 of 3)

struct SignupInitialView: View {

    @StateObject private var viewModel: SignupInitialViewModel

    // UI-only animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 18

    let currentStep: Int = 1
    let totalSteps: Int = 3
    var onContinue: () -> Void

    // MARK: Inits

    init(
        viewModel: SignupInitialViewModel = SignupInitialViewModel(),
        onContinue: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContinue = onContinue
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
                    SignupHeaderSection(title: "Set New Password")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 52)
                        .padding(.bottom, 36)

                    SignupStepIndicator(
                        currentStep: currentStep,
                        totalSteps: totalSteps
                    )
                    .padding(.bottom, 28)

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
                        Task { await viewModel.attemptContinue() }
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
        .onChange(of: viewModel.isComplete) { newValue in
            if newValue { onContinue() }
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
            .onChange(of: viewModel.username) { _ in viewModel.usernameDidChange() }

            SignupValidatedField(
                placeholder: "Email",
                text: $viewModel.email,
                error: viewModel.emailError,
                keyboardType: .emailAddress
            )
            .onChange(of: viewModel.email) { _ in viewModel.emailDidChange() }

            SignupValidatedField(
                placeholder: "Password",
                text: $viewModel.password,
                error: viewModel.passwordError,
                isSecure: true
            )
            .onChange(of: viewModel.password) { _ in viewModel.passwordDidChange() }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    SignupInitialView()
        .preferredColorScheme(.dark)
}

#Preview("All Errors") {
    SignupInitialView(viewModel: SignupInitialViewModel(
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
    SignupInitialView(viewModel: SignupInitialViewModel(
        username: "",
        usernameError: "Username is required",
        didAttemptContinue: true
    ))
    .preferredColorScheme(.dark)
}

#Preview("Valid — Ready to Continue") {
    SignupInitialView(viewModel: SignupInitialViewModel(
        username: "johndoe",
        email: "john@example.com",
        password: "Secure123!"
    ))
    .preferredColorScheme(.dark)
}
