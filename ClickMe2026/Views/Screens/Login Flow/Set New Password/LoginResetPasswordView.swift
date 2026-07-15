//
//  LoginResetPasswordView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Password Strength

enum PasswordStrength: Int, CaseIterable {
    case empty, weak, fair, strong

    var label: String {
        switch self {
        case .empty: return ""
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .strong: return "Strong"
        }
    }

    var color: Color {
        switch self {
        case .empty: return Color.white.opacity(0.15)
        case .weak: return Color(red: 0.85, green: 0.22, blue: 0.22)
        case .fair: return Color(red: 0.95, green: 0.65, blue: 0.10)
        case .strong: return Brand.primary
        }
    }

    static func evaluate(_ password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .empty }
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.range(of: #"[A-Z]"#, options: .regularExpression) != nil { score += 1 }
        if password.range(of: #"[0-9]"#, options: .regularExpression) != nil { score += 1 }
        if password.range(of: #"[^A-Za-z0-9]"#, options: .regularExpression) != nil { score += 1 }
        switch score {
        case 0 ... 1: return .weak
        case 2 ... 3: return .fair
        default: return .strong
        }
    }
}

// MARK: - Set New Password Screen

struct LoginResetPasswordView: View {

    @StateObject private var viewModel: LoginResetPasswordViewModel

    // UI-only state
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 16

    var onSuccess: () -> Void

    // MARK: Inits

    init(
        viewModel: LoginResetPasswordViewModel = LoginResetPasswordViewModel(),
        onSuccess: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSuccess = onSuccess
    }

    // MARK: Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [NewPasswordBrand.bgTop, NewPasswordBrand.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        fieldLabel("Verification Code")
                            .padding(.top, 28)
                            .padding(.horizontal, 24)

                        NewPasswordCodeField(
                            placeholder: "Enter 6-digit code",
                            text: $viewModel.code,
                            error: viewModel.codeError
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .onChange(of: viewModel.code) { _, newValue in
                            // Strip non-digits and cap at 6 characters.
                            let digits = newValue.filter(\.isNumber)
                            let clipped = String(digits.prefix(6))
                            if clipped != newValue {
                                viewModel.code = clipped
                            }
                            viewModel.codeDidChange()
                        }

                        Spacer().frame(height: 24)

                        fieldLabel("New Password")
                            .padding(.horizontal, 24)

                        NewPasswordField(
                            placeholder: "Enter your new password",
                            text: $viewModel.newPassword,
                            isVisible: $showNewPassword,
                            error: viewModel.newPasswordError
                        ) {
                            strengthBadge
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .onChange(of: viewModel.newPassword) {
                            viewModel.newPasswordDidChange()
                        }

                        Spacer().frame(height: 24)

                        fieldLabel("Confirm New Password")
                            .padding(.horizontal, 24)

                        NewPasswordField(
                            placeholder: "Confirm your new password",
                            text: $viewModel.confirmPassword,
                            isVisible: $showConfirmPassword,
                            error: viewModel.confirmPasswordError
                        ) {
                            confirmMatchBadge
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .onChange(of: viewModel.confirmPassword) {
                            viewModel.confirmPasswordDidChange()
                        }

                        if !viewModel.newPassword.isEmpty {
                            PasswordStrengthMeter(strength: viewModel.strength)
                                .padding(.horizontal, 24)
                                .padding(.top, 14)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Spacer().frame(height: 40)
                    }
                }

                NewPasswordSubmitButton(
                    isLoading: viewModel.isLoading,
                    isSuccess: viewModel.isSuccess
                ) {
                    Task { await viewModel.attemptSubmit() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Set New Password")
        .navigationBarTitleDisplayMode(.inline)
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .onChange(of: viewModel.isSuccess) { _, newValue in
            if newValue { onSuccess() }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.newPassword.isEmpty)
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
    private func presenting(_ keyPath: ReferenceWritableKeyPath<LoginResetPasswordViewModel, String?>) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { if !$0 { viewModel[keyPath: keyPath] = nil } }
        )
    }

    // MARK: Inline helpers

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
    }

    @ViewBuilder
    private var strengthBadge: some View {
        if !viewModel.newPassword.isEmpty && viewModel.strength != .empty {
            Text(viewModel.strength.label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(viewModel.strength.color)
        }
    }

    @ViewBuilder
    private var confirmMatchBadge: some View {
        if viewModel.passwordsMatch {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(NewPasswordBrand.green)
        }
    }
}

// MARK: - Previews

#if DEBUG
private func newPasswordPreview(_ vm: LoginResetPasswordViewModel) -> some View {
    PreviewNavHarness(parentText: "Reset password link", navTitle: "Reset password", rowTitle: "Set new password") {
        LoginResetPasswordView(viewModel: vm)
    }
    .preferredColorScheme(.dark)
}
#endif

#Preview("Default") {
    newPasswordPreview(LoginResetPasswordViewModel(email: "john.doe@example.com"))
}

#Preview("Weak Password") {
    newPasswordPreview(LoginResetPasswordViewModel(
        email: "john.doe@example.com",
        code: "123456",
        newPassword: "abc"
    ))
}

#Preview("Fair Password") {
    newPasswordPreview(LoginResetPasswordViewModel(
        email: "john.doe@example.com",
        code: "123456",
        newPassword: "Abcdef12",
        confirmPassword: "Abcdef12"
    ))
}

#Preview("Strong Password") {
    newPasswordPreview(LoginResetPasswordViewModel(
        email: "john.doe@example.com",
        code: "123456",
        newPassword: "Abcdef12!@#",
        confirmPassword: "Abcdef12!@#"
    ))
}

#Preview("Both Errors") {
    newPasswordPreview(LoginResetPasswordViewModel(
        email: "john.doe@example.com",
        code: "12",
        newPassword: "abc",
        confirmPassword: "xyz",
        codeError: "Code must be 6 digits",
        newPasswordError: "Password must be at least 8 characters",
        confirmPasswordError: "Passwords do not match",
        didAttemptSubmit: true
    ))
}

#Preview("Bad Code") {
    newPasswordPreview(LoginResetPasswordViewModel(
        email: "john.doe@example.com",
        code: "999999",
        newPassword: "Abcdef12!@#",
        confirmPassword: "Abcdef12!@#",
        codeError: "Invalid or expired code. Please request a new one.",
        didAttemptSubmit: true
    ))
}
