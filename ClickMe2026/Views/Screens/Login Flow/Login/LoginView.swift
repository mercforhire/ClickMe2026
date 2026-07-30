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
    case tags
    case review
}

// MARK: - Login Screen

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    /// Fires when the user reaches a home destination. The mode passed
    /// is the landing decision — either `.expert` (role=expert AND has
    /// ≥1 topic) or `.client` (everyone else). The parent uses it to
    /// pick the correct home route.
    var onSuccess: (AppMode) -> Void

    // Navigation — heterogeneous stack across login / password-reset / signup flows
    @State private var path: NavigationPath

    /// Shared payload store owned by the login screen for the duration of a
    /// signup flow. `@State` so the same instance is threaded through every
    /// pushed destination without re-initializing.
    @State private var signupAccumulator: SignupAccumulator

    // UI-only animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    init(
        viewModel: LoginViewModel = LoginViewModel(),
        startAtSignupSetup: Bool = false,
        hydrateFrom expertProfile: ExpertProfileData? = nil,
        onSuccess: @escaping (AppMode) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSuccess = onSuccess

        // Seed the accumulator BEFORE it gets wrapped in @State — each
        // signup step's ViewModel snapshots the accumulator at init, so
        // hydrating later (in .task / .onAppear) would be too late.
        let accumulator = SignupAccumulator()
        if let expertProfile {
            accumulator.hydrate(from: expertProfile)
        }
        _signupAccumulator = State(initialValue: accumulator)

        // Seed the nav stack so the first-rendered screen is the Overview
        // checklist rather than the login form. Used when the splash
        // detects an already-authed expert whose profile setup never
        // completed — they land on the hub and can pick any remaining
        // checklist item to finish.
        var initialPath = NavigationPath()
        if startAtSignupSetup {
            initialPath.append(SignupRoute.overview)
        }
        _path = State(initialValue: initialPath)
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
                            onContinue: {
                                // Account has been created on the backend at
                                // this point — the user must NOT be able to
                                // nav back to Create Account (a resubmit
                                // would 409). Reset the path so Overview
                                // sits directly under Login; back-chevron
                                // takes them to the login screen instead.
                                path = NavigationPath()
                                path.append(SignupRoute.overview)
                            }
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
                        // Overview → Basic Info → Overview. Pop back after
                        // a successful save so the checklist re-renders
                        // with the row ✓.
                        SignupBasicInfoView(
                            accumulator: signupAccumulator,
                            onContinue: { _ in path.removeLast() }
                        )
                    case .timezone:
                        // Overview → Timezone → Overview. Same round-trip
                        // as Basic Info.
                        SignupTimezoneView(
                            accumulator: signupAccumulator,
                            onNext: { path.removeLast() }
                        )
                    case .overview:
                        SignupOverviewView(
                            accumulator: signupAccumulator,
                            onNext: { path.append(SignupRoute.review) },
                            onChecklistItemTap: { item in
                                switch item.kind {
                                case .basicInfo:
                                    path.append(SignupRoute.basicInfo)
                                case .timezone:
                                    path.append(SignupRoute.timezone)
                                case .profilePicture:
                                    path.append(SignupRoute.profilePhoto)
                                case .verifyEmail:
                                    path.append(SignupRoute.verifyEmail)
                                case .expertise:
                                    path.append(SignupRoute.tags)
                                }
                            }
                        )
                    case .profilePhoto:
                        // Overview → Profile Photo → Overview. Pop back
                        // after upload succeeds so the checklist re-renders
                        // with the "Profile Picture" row ✓.
                        SignupProfilePhotoView(
                            accumulator: signupAccumulator,
                            onSave: { _ in path.removeLast() }
                        )
                    case .verifyEmail:
                        SignupVerifyEmailView(
                            accumulator: signupAccumulator,
                            onChangeEmail: { path.removeLast() },
                            onVerified: { path.removeLast() }
                        )
                    case .tags:
                        // Overview → Tags → Overview. Pop back so the
                        // checklist re-renders with the "Add expertise"
                        // row ✓.
                        SignupTagsView(
                            accumulator: signupAccumulator,
                            onDone: { _ in path.removeLast() }
                        )
                    case .review:
                        SignupReviewView(
                            accumulator: signupAccumulator,
                            onPublish: {
                                // Fresh expert always lands on client home
                                // — they haven't published any topics yet,
                                // so the expert dashboard would be empty.
                                // They can flip to expert mode manually from
                                // the profile hub once they add a topic.
                                UserManager.shared.setMode(.client)
                                onSuccess(.client)
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
                            if let roles = await viewModel.attemptLogin() {
                                let isExpert = roles.contains(.expert)
                                if isExpert, await isExpertProfileIncomplete() {
                                    // The account has the expert role but never
                                    // completed expert-profile setup. Hydrate the
                                    // accumulator from whatever the server has so
                                    // far and drop the user on the Overview
                                    // checklist so they can pick any remaining
                                    // item to finish setup.
                                    if let expertProfile = UserManager.shared.expertProfile {
                                        signupAccumulator.hydrate(from: expertProfile)
                                    }
                                    path.append(SignupRoute.overview)
                                } else {
                                    // Landing decision: expert home only when
                                    // roles.contains(.expert) AND ≥1 topic exists
                                    // — a fresh expert with no topics lands on
                                    // client home so they don't see an empty
                                    // expert dashboard.
                                    let mode: AppMode
                                    if isExpert, await UserManager.shared.expertHasTopics() {
                                        mode = .expert
                                    } else {
                                        mode = .client
                                    }
                                    UserManager.shared.setMode(mode)
                                    onSuccess(mode)
                                }
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

    /// True when the freshly-authed expert has never completed the setup
    /// flow. Reads the authoritative `setup_completed` flag from
    /// `GET /expert/profile`. On a transient network failure we default
    /// to `false` (i.e. treat as "complete") so we don't punt completed
    /// users back into signup because of one flaky request.
    private func isExpertProfileIncomplete() async -> Bool {
        do {
            try await UserManager.shared.refreshExpertProfile()
        } catch {
            return false
        }
        return UserManager.shared.expertProfile?.setupCompleted == false
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
