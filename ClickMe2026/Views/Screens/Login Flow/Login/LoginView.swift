//
//  LoginView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Login navigation routes

/// Routes directly reachable from the login screen.
private enum LoginRoute: Hashable {
    case forgotPassword
    case signUp
}

/// Downstream routes in the password-reset flow.
private enum PasswordResetRoute: Hashable {
    /// The user requested a code from `/auth/password/forgot`. Carries the
    /// email/identity forward so the next screen can call `/auth/password/reset`.
    case setNewPassword(email: String)
    case passwordUpdated
}

/// Downstream routes in the sign-up flow. Ordered by the linear happy-path;
/// `overview` is the fan-out hub that lets the user hop into any remaining
/// checklist item.
private enum SignupRoute: Hashable {
    case basicInfo
    case timezone
    case overview
    case profilePhoto
    case verifyEmail
    case hourlyRate
    case tags
    case review
}

// MARK: - Login Screen

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    var onSuccess: (UserRole) -> Void

    // Navigation — heterogeneous stack across login / password-reset / signup flows
    @State private var path = NavigationPath()

    /// Shared payload store owned by the login screen for the duration of a
    /// signup flow. `@State` so the same instance is threaded through every
    /// pushed destination without re-initializing.
    @State private var signupAccumulator = SignupAccumulator()

    // UI-only animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    init(
        viewModel: LoginViewModel = LoginViewModel(),
        onSuccess: @escaping (UserRole) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: LoginRoute.self) { route in
                    switch route {
                    case .forgotPassword:
                        LoginForgetPassView(
                            viewModel: LoginForgetPassViewModel(email: viewModel.email),
                            onCodeSent: { email in
                                path.append(PasswordResetRoute.setNewPassword(email: email))
                            }
                        )
                    case .signUp:
                        SignupInitialView(
                            accumulator: signupAccumulator,
                            onContinue: { path.append(SignupRoute.basicInfo) }
                        )
                    }
                }
                .navigationDestination(for: PasswordResetRoute.self) { route in
                    switch route {
                    case .setNewPassword(let email):
                        LoginResetPasswordView(
                            viewModel: LoginResetPasswordViewModel(email: email),
                            onSuccess: { path.append(PasswordResetRoute.passwordUpdated) }
                        )
                    case .passwordUpdated:
                        LoginPasswordSetView(
                            onGoToLogin: { path = NavigationPath() }
                        )
                    }
                }
                .navigationDestination(for: SignupRoute.self) { route in
                    switch route {
                    case .basicInfo:
                        SignupBasicInfoView(
                            accumulator: signupAccumulator,
                            onContinue: { _ in path.append(SignupRoute.timezone) }
                        )
                    case .timezone:
                        SignupTimezoneView(
                            accumulator: signupAccumulator,
                            onNext: { path.append(SignupRoute.overview) }
                        )
                    case .overview:
                        SignupOverviewView(
                            accumulator: signupAccumulator,
                            onNext: { path.append(SignupRoute.review) },
                            onChecklistItemTap: { item in
                                switch item.kind {
                                case .profilePicture:
                                    path.append(SignupRoute.profilePhoto)
                                case .verifyEmail:
                                    path.append(SignupRoute.verifyEmail)
                                case .hourlyRate:
                                    path.append(SignupRoute.hourlyRate)
                                case .expertise:
                                    path.append(SignupRoute.tags)
                                }
                            }
                        )
                    case .profilePhoto:
                        SignupProfilePhotoView(accumulator: signupAccumulator)
                    case .verifyEmail:
                        SignupVerifyEmailView(
                            accumulator: signupAccumulator,
                            onChangeEmail: { path.removeLast() },
                            onVerified: { path.removeLast() }
                        )
                    case .hourlyRate:
                        ClickMeSetHourlyRateView(accumulator: signupAccumulator)
                    case .tags:
                        SignupTagsView(accumulator: signupAccumulator)
                    case .review:
                        SignupReviewView(
                            accumulator: signupAccumulator,
                            onPublish: {
                                // Log the freshly-created expert in as their own client-of-record
                                // so the app can transition into the main tab experience.
                                onSuccess(.expert)
                            }
                        )
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
                            path.append(LoginRoute.forgotPassword)
                        }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(LoginBrand.green)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    LoginButton(isLoading: viewModel.isLoading) {
                        Task {
                            if let role = await viewModel.attemptLogin() {
                                onSuccess(role)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    SignUpFooter(onSignUp: { path.append(LoginRoute.signUp) })
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
            .onChange(of: viewModel.email) { viewModel.emailDidChange() }

            ValidatedField(
                placeholder: "Password",
                text: $viewModel.password,
                icon: "lock",
                isSecure: true,
                error: viewModel.passwordError
            )
            .onChange(of: viewModel.password) { viewModel.passwordDidChange() }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    LoginView(viewModel: LoginViewModel(
        email: "",
        password: "",
        emailError: nil,
        passwordError: nil,
        didAttemptLogin: false
    ))
    .preferredColorScheme(.dark)
}

#Preview("Loading") {
    LoginView(viewModel: LoginViewModel(
        email: "john.doe@example.com",
        password: "••••••••",
        isLoading: true
    ))
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
