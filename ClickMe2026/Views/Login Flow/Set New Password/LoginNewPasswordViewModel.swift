//
//  LoginNewPasswordViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class LoginNewPasswordViewModel: ObservableObject {

    // MARK: Form state
    @Published var newPassword: String
    @Published var confirmPassword: String

    // MARK: Validation state
    @Published var newPasswordError: String?
    @Published var confirmPasswordError: String?
    @Published var didAttemptSubmit: Bool

    // MARK: Submission state
    @Published var isLoading: Bool = false
    @Published var isSuccess: Bool = false

    // MARK: API feedback
    @Published var apiError: String?
    @Published var successMessage: String?

    /// Reset-password token, typically delivered via the password-reset email
    /// deep link.
    let token: String

    private let api: ClickMeAPI

    init(
        token: String = "",
        newPassword: String = "",
        confirmPassword: String = "",
        newPasswordError: String? = nil,
        confirmPasswordError: String? = nil,
        didAttemptSubmit: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.token = token
        self.newPassword = newPassword
        self.confirmPassword = confirmPassword
        self.newPasswordError = newPasswordError
        self.confirmPasswordError = confirmPasswordError
        self.didAttemptSubmit = didAttemptSubmit
        self.api = api
    }

    // MARK: Derived

    var strength: PasswordStrength {
        PasswordStrength.evaluate(newPassword)
    }

    var passwordsMatch: Bool {
        !confirmPassword.isEmpty && confirmPassword == newPassword
    }

    // MARK: Validation

    func validateNewPassword() {
        if newPassword.isEmpty {
            newPasswordError = "Please enter a new password"
        } else if newPassword.count < 8 {
            newPasswordError = "Password must be at least 8 characters"
        } else {
            newPasswordError = nil
        }
    }

    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
        } else if confirmPassword != newPassword {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = nil
        }
    }

    /// Revalidate the new-password field after edits, once a submit has been attempted.
    func newPasswordDidChange() {
        if didAttemptSubmit { validateNewPassword() }
    }

    func confirmPasswordDidChange() {
        if didAttemptSubmit { validateConfirmPassword() }
    }

    // MARK: Submit

    func attemptSubmit() async {
        didAttemptSubmit = true
        validateNewPassword()
        validateConfirmPassword()
        guard newPasswordError == nil, confirmPasswordError == nil else { return }
        guard !token.isEmpty else {
            apiError = "Missing reset token. Please use the link from your email again."
            return
        }

        apiError = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await api.resetPassword(
                token: token,
                password: newPassword,
                passwordConfirmation: confirmPassword
            )
            successMessage = response.message
            isSuccess = true
        } catch {
            apiError = Self.message(for: error)
        }
    }

    // MARK: Helpers

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
