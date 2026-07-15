//
//  LoginNewPasswordView.swift
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
        case .strong: return Color(red: 0.22, green: 0.82, blue: 0.44)
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

struct LoginNewPasswordView: View {

    @StateObject private var viewModel: LoginNewPasswordViewModel

    // UI-only state
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 16

    var onSuccess: () -> Void

    // MARK: Inits

    init(
        viewModel: LoginNewPasswordViewModel = LoginNewPasswordViewModel(),
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
                        NewPasswordHeaderSection()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 52)
                            .padding(.bottom, 36)

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
                        .padding(.top, 8)
                        .onChange(of: viewModel.newPassword) { _ in
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
                        .padding(.top, 8)
                        .onChange(of: viewModel.confirmPassword) { _ in
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
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .onChange(of: viewModel.isSuccess) { newValue in
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
    private func presenting(_ keyPath: ReferenceWritableKeyPath<LoginNewPasswordViewModel, String?>) -> Binding<Bool> {
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

#Preview("Default") {
    LoginNewPasswordView()
        .preferredColorScheme(.dark)
}

#Preview("Weak Password") {
    LoginNewPasswordView(viewModel: LoginNewPasswordViewModel(
        newPassword: "abc"
    ))
    .preferredColorScheme(.dark)
}

#Preview("Fair Password") {
    LoginNewPasswordView(viewModel: LoginNewPasswordViewModel(
        newPassword: "Abcdef12",
        confirmPassword: "Abcdef12"
    ))
    .preferredColorScheme(.dark)
}

#Preview("Strong Password") {
    LoginNewPasswordView(viewModel: LoginNewPasswordViewModel(
        newPassword: "Abcdef12!@#",
        confirmPassword: "Abcdef12!@#"
    ))
    .preferredColorScheme(.dark)
}

#Preview("Both Errors") {
    LoginNewPasswordView(viewModel: LoginNewPasswordViewModel(
        newPassword: "abc",
        confirmPassword: "xyz",
        newPasswordError: "Password must be at least 8 characters",
        confirmPasswordError: "Passwords do not match",
        didAttemptSubmit: true
    ))
    .preferredColorScheme(.dark)
}
