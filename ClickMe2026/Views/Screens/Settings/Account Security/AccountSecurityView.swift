//
//  ChangePasswordView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-09.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

private enum ChangePasswordBrand {
    static let pageBg = Color.black
    static let inputBg = Color(red: 0.110, green: 0.106, blue: 0.106) // #1c1b1b
    static let inputBorder = Color(red: 0.235, green: 0.290, blue: 0.247).opacity(0.40) // #3c4a3f / 40%
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592) // #44f697
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114) // #00391d
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882) // #e5e2e1
    static let onSurfaceVar = Color(red: 0.729, green: 0.796, blue: 0.737) // #bacbbc
    static let strengthTrack = Color(red: 0.208, green: 0.208, blue: 0.204).opacity(0.30)
    static let error = Color(red: 1.000, green: 0.706, blue: 0.671) // #ffb4ab
    static let warning = Color(red: 0.918, green: 0.702, blue: 0.031) // yellow-500
    static let neonGlow = Color(red: 0.000, green: 0.851, blue: 0.494).opacity(0.30) // rgba(0,217,126,0.3)
    static let dangerRed = Color(red: 1.000, green: 0.302, blue: 0.302) // #ff4d4d
    static let sectionDivider = Color(red: 0.165, green: 0.165, blue: 0.165) // #2a2a2a
}

// MARK: - Strength model

private enum ChangePasswordStrength: Int {
    case weak = 1
    case fair = 2
    case good = 3
    case secure = 4

    static func score(for value: String) -> ChangePasswordStrength {
        guard !value.isEmpty else { return .weak }
        var s = 0
        if value.count > 8 { s += 1 }
        if value.range(of: "[A-Z]", options: .regularExpression) != nil { s += 1 }
        if value.range(of: "[0-9]", options: .regularExpression) != nil { s += 1 }
        if value.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { s += 1 }
        switch s {
        case 0, 1: return .weak
        case 2:    return .fair
        case 3:    return .good
        default:   return .secure
        }
    }

    var label: String {
        switch self {
        case .weak:   return "Strength: Weak"
        case .fair:   return "Strength: Fair"
        case .good:   return "Strength: Good"
        case .secure: return "Strength: Secure"
        }
    }

    var color: Color {
        switch self {
        case .weak:   return ChangePasswordBrand.error
        case .fair:   return ChangePasswordBrand.warning
        case .good:   return ChangePasswordBrand.brandGreen.opacity(0.60)
        case .secure: return ChangePasswordBrand.brandGreen
        }
    }

    /// Fraction of the track filled by the bar.
    var fill: CGFloat {
        switch self {
        case .weak:   return 0.25
        case .fair:   return 0.50
        case .good:   return 0.75
        case .secure: return 1.00
        }
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {

    @StateObject private var viewModel: ChangePasswordViewModel

    init(viewModel: ChangePasswordViewModel = ChangePasswordViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ChangePasswordBrand.pageBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    VStack(spacing: 14) {
                        PasswordField(
                            label: "Current Password",
                            text: $viewModel.currentPassword,
                            isVisible: $viewModel.showCurrent,
                            errorMessage: viewModel.currentPasswordError
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            PasswordField(
                                label: "New Password",
                                text: $viewModel.newPassword,
                                isVisible: $viewModel.showNew,
                                errorMessage: viewModel.newPasswordError
                            )
                            StrengthIndicator(
                                strength: ChangePasswordStrength.score(for: viewModel.newPassword),
                                isEmpty: viewModel.newPassword.isEmpty
                            )
                        }

                        PasswordField(
                            label: "Confirm New Password",
                            text: $viewModel.confirmPassword,
                            isVisible: $viewModel.showConfirm,
                            errorMessage: viewModel.confirmPasswordError
                        )
                    }

                    updateButton
                        .padding(.top, 8)

                    deleteAccountSection
                        .padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Account Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ChangePasswordBrand.pageBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(
            "Couldn't update password",
            isPresented: Binding(
                get: { viewModel.apiError != nil },
                set: { if !$0 { viewModel.apiError = nil } }
            ),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert("Password updated", isPresented: $viewModel.didSucceed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your password has been changed.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Change Password")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ChangePasswordBrand.onSurface)
            Text("Your new password must be at least 8 characters long and include numbers.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(ChangePasswordBrand.onSurfaceVar)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Delete account section

    /// Danger section below the password form. Tapping the button pushes
    /// `DeleteAccountView` onto the enclosing NavigationStack; that screen
    /// runs its own two-step confirmation + reason flow before actually
    /// deleting anything, so no destructive action fires from a single tap
    /// here.
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(ChangePasswordBrand.sectionDivider)
                .frame(height: 1)
                .padding(.bottom, 12)

            Text("Delete Account")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ChangePasswordBrand.onSurface)

            Text("Once you delete your account, there is no going back. Please be certain.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(ChangePasswordBrand.onSurfaceVar)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                // After a successful deletion the farewell screen shows first
                // (see `DeleteAccountViewModel.confirmDeletion`); tapping its
                // "Back to Login" button wipes the local session here, which
                // trips the app-level router (`ClickMe2026App.onChange(of:
                // userManager.isLoggedIn)`) and lands the user on Login.
                DeleteAccountView(
                    onBackToLogin: { UserManager.shared.logout() }
                )
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Delete Account")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(ChangePasswordBrand.dangerRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ChangePasswordBrand.dangerRed.opacity(0.55), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: - Update button

    private var updateButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            ZStack {
                Text("Update Password")
                    .opacity(viewModel.isSubmitting ? 0 : 1)
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(ChangePasswordBrand.onPrimary)
                }
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(ChangePasswordBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ChangePasswordBrand.brandGreen.opacity(viewModel.canSubmit ? 1.0 : 0.55))
            )
            .shadow(
                color: ChangePasswordBrand.neonGlow.opacity(viewModel.canSubmit ? 1.0 : 0.0),
                radius: 10,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit)
    }
}

// MARK: - Password field row

private struct PasswordField: View {
    let label: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var errorMessage: String?

    @FocusState private var isFocused: Bool

    private var borderColor: Color {
        if errorMessage != nil { return ChangePasswordBrand.error }
        if isFocused { return ChangePasswordBrand.brandGreen }
        return ChangePasswordBrand.inputBorder
    }

    private var borderWidth: CGFloat {
        (errorMessage != nil || isFocused) ? 1.5 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .kerning(0.26)
                .foregroundColor(ChangePasswordBrand.onSurfaceVar)
                .padding(.leading, 4)

            HStack(spacing: 0) {
                Group {
                    if isVisible {
                        TextField("••••••••", text: $text)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    } else {
                        SecureField("••••••••", text: $text)
                    }
                }
                .focused($isFocused)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(ChangePasswordBrand.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ChangePasswordBrand.onSurfaceVar)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 2)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ChangePasswordBrand.inputBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ChangePasswordBrand.error)
                    .padding(.leading, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Strength indicator

private struct StrengthIndicator: View {
    let strength: ChangePasswordStrength
    let isEmpty: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(strength.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isEmpty ? ChangePasswordBrand.onSurfaceVar : strength.color)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ChangePasswordBrand.strengthTrack)
                    Capsule()
                        .fill(strength.color)
                        .frame(width: isEmpty ? 0 : proxy.size.width * strength.fill)
                        .animation(.easeInOut(duration: 0.3), value: strength)
                        .animation(.easeInOut(duration: 0.3), value: isEmpty)
                }
            }
            .frame(height: 4)
        }
        .padding(.leading, 4)
        .padding(.top, 4)
    }
}

// MARK: - Preview harness

private enum ChangePasswordPreviewRoute: Hashable {
    case changePassword
}

/// Wraps the change-password screen inside a NavigationStack with a dummy
/// "Settings" parent already pushed, so the system back chevron renders in
/// the canvas — matches how the hub pushes this screen in production.
private struct ChangePasswordPreviewHarness: View {
    let viewModel: ChangePasswordViewModel
    @State private var path: [ChangePasswordPreviewRoute]

    init(viewModel: ChangePasswordViewModel = ChangePasswordViewModel()) {
        self.viewModel = viewModel
        _path = State(initialValue: [.changePassword])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Account")
                NavigationLink("Security & Password", value: ChangePasswordPreviewRoute.changePassword)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: ChangePasswordPreviewRoute.self) { _ in
                ChangePasswordView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Live-fetch preview harness

/// Wraps the change-password screen inside a NavigationStack with a dummy
/// "Settings" parent and installs the client bearer token, so tapping
/// **Update Password** performs a real `PATCH /user/password` call against
/// the live backend. Change either password to confirm the round-trip works
/// end-to-end (403 / 422 / 200 all handled by the view model).
private struct LiveFetchChangePasswordPreviewHarness: View {
    @State private var path: [ChangePasswordPreviewRoute]

    init() {
        _path = State(initialValue: [.changePassword])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Account")
                NavigationLink("Security & Password", value: ChangePasswordPreviewRoute.changePassword)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: ChangePasswordPreviewRoute.self) { _ in
                ChangePasswordView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Change Password") {
    ChangePasswordPreviewHarness()
        .preferredColorScheme(.dark)
}

#Preview("Filled — Valid Inputs") {
    ChangePasswordPreviewHarness(
        viewModel: .previewSeed(
            current: "OldPass2025!",
            new: "N3wStr0ngPass!",
            confirm: "N3wStr0ngPass!"
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return LiveFetchChangePasswordPreviewHarness()
        .preferredColorScheme(.dark)
}
