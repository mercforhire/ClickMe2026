//
//  LoginViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: Form state
    @Published var email: String
    @Published var password: String
    @Published var isLoading: Bool = false

    // MARK: Validation state
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var didAttemptLogin: Bool

    // MARK: API feedback
    @Published var apiError: String?

    private let userManager: UserManager

    init(
        email: String = "",
        password: String = "",
        emailError: String? = nil,
        passwordError: String? = nil,
        didAttemptLogin: Bool = false,
        isLoading: Bool = false,
        userManager: UserManager = .shared
    ) {
        self.email = email
        self.password = password
        self.emailError = emailError
        self.passwordError = passwordError
        self.didAttemptLogin = didAttemptLogin
        self.isLoading = isLoading
        self.userManager = userManager
    }

    // MARK: Validation

    /// Email is the sole login handle.
    func validateEmail() {
        let emailPattern = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            emailError = "Email is required"
        } else if trimmed.range(of: emailPattern, options: .regularExpression) == nil {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }

    func validatePassword() {
        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else {
            passwordError = nil
        }
    }

    /// Revalidate the email field whenever the user edits it — but only after
    /// the first login attempt, to avoid showing errors before they've tried.
    func emailDidChange() {
        if didAttemptLogin { validateEmail() }
    }

    func passwordDidChange() {
        if didAttemptLogin { validatePassword() }
    }

    // MARK: Login

    /// Attempts a login. On success returns the authenticated user's roles
    /// so the caller can route to the appropriate home screen. On
    /// failure, populates `apiError` (and `passwordError` for 401s).
    @discardableResult
    func attemptLogin() async -> [UserRole]? {
        didAttemptLogin = true
        // iOS keyboards frequently append a trailing space after
        // period-double-tap or autocomplete when the user types their
        // email — the server's strict email validator then 422s. Trim
        // before both validating and sending so the value on the wire
        // matches what the user meant to type.
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        validateEmail()
        validatePassword()
        guard emailError == nil, passwordError == nil else { return nil }

        apiError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await userManager.login(email: email, password: password)
            return user.roles
        } catch {
            handle(loginError: error)
            return nil
        }
    }

    // MARK: Helpers

    private func handle(loginError error: Error) {
        guard case let NetworkError.httpError(statusCode, data) = error else {
            apiError = Self.message(for: error)
            return
        }

        // 422 → syntax-only email validation failure (not an email string).
        // Server returns `errors[0] = { field: "email", message: ... }` with
        // no `code`. Surface inline on the email field and skip the alert.
        // See `docs/ios/SIGNUP-USERNAME-OPTIONAL.md` §2.
        if statusCode == 422,
           let response = try? JSONDecoder().decode(FieldValidationErrorResponse.self, from: data),
           let fieldError = response.errors.first(where: { $0.field == "email" })
        {
            emailError = fieldError.message
            return
        }

        // 401 → wrong credentials or unknown email. Server returns a
        // deliberately generic `{ message: "Invalid email or password" }`
        // (no `code`) so neither field can be verified from the response.
        // Mirror the generic message on both inline fields + top alert.
        if statusCode == 401 {
            passwordError = Self.message(for: error)
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
