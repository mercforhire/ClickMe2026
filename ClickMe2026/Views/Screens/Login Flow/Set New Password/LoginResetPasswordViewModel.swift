//
//  LoginResetPasswordViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class LoginResetPasswordViewModel: ObservableObject {

    // MARK: Form state
    @Published var code: String
    @Published var newPassword: String
    @Published var confirmPassword: String

    // MARK: Validation state
    @Published var codeError: String?
    @Published var newPasswordError: String?
    @Published var confirmPasswordError: String?
    @Published var didAttemptSubmit: Bool

    // MARK: Submission state
    @Published var isLoading: Bool = false
    @Published var isSuccess: Bool = false

    // MARK: API feedback
    @Published var apiError: String?
    @Published var successMessage: String?

    /// Email whose password we're resetting. Populated by the previous
    /// step (forgot-password); reused when calling `/auth/password/reset`.
    let email: String

    private let api: ClickMeAPI

    init(
        email: String = "",
        code: String = "",
        newPassword: String = "",
        confirmPassword: String = "",
        codeError: String? = nil,
        newPasswordError: String? = nil,
        confirmPasswordError: String? = nil,
        didAttemptSubmit: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.email = email
        self.code = code
        self.newPassword = newPassword
        self.confirmPassword = confirmPassword
        self.codeError = codeError
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

    func validateCode() {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            codeError = "Please enter the 6-digit code"
        } else if trimmed.range(of: #"^\d{6}$"#, options: .regularExpression) == nil {
            codeError = "Code must be 6 digits"
        } else {
            codeError = nil
        }
    }

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

    /// Revalidate a field after edits, once a submit has been attempted.
    func codeDidChange() {
        if didAttemptSubmit { validateCode() }
    }

    func newPasswordDidChange() {
        if didAttemptSubmit { validateNewPassword() }
    }

    func confirmPasswordDidChange() {
        if didAttemptSubmit { validateConfirmPassword() }
    }

    // MARK: Submit

    func attemptSubmit() async {
        didAttemptSubmit = true
        validateCode()
        validateNewPassword()
        validateConfirmPassword()
        guard codeError == nil,
              newPasswordError == nil,
              confirmPasswordError == nil
        else { return }

        guard !email.isEmpty else {
            apiError = "Missing account email. Please start the reset flow again from the login screen."
            return
        }

        apiError = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let response = try await api.resetPassword(
                email: email,
                code: trimmedCode,
                password: newPassword,
                passwordConfirmation: confirmPassword
            )
            successMessage = response.message
            isSuccess = true
        } catch {
            handle(resetError: error)
        }
    }

    // MARK: Helpers

    private func handle(resetError error: Error) {
        if case let NetworkError.httpError(statusCode, data) = error {
            // 400 EXPIRED_TOKEN — bad / expired / used / max-attempts / unknown email.
            // Surface inline on the code field so the user knows to request a fresh one.
            if statusCode == 400 {
                codeError = "Invalid or expired code. Please request a new one."
            }

            // 422 VALIDATION_ERROR — surface any field errors returned by the server.
            if statusCode == 422,
               let response = try? JSONDecoder().decode(FieldValidationErrorResponse.self, from: data)
            {
                for fieldError in response.errors {
                    switch fieldError.field {
                    case "password":
                        newPasswordError = fieldError.message
                    case "password_confirmation":
                        confirmPasswordError = fieldError.message
                    case "code":
                        codeError = fieldError.message
                    case "email":
                        apiError = fieldError.message
                    default:
                        break
                    }
                }
            }
        }
        apiError = Self.message(for: error)
    }

    /// Prefers a server-provided message (from `StandardErrorResponse.message`)
    /// when available; falls back to a `LocalizedError` description or the
    /// system message.
    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
