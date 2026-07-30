//
//  LoginViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-21.
//  Copyright © 2026 Q42. All rights reserved.
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

    /// `POST /auth/login` accepts either an email or a username under the
    /// `email` key. Client-side validation matches either format so we
    /// don't gate valid identifiers behind an email-only rule.
    func validateEmail() {
        let emailPattern = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        let usernamePattern = #"^[A-Za-z0-9_.]{3,30}$"#
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            emailError = "Email or username is required"
        } else if trimmed.range(of: emailPattern, options: .regularExpression) == nil,
                  trimmed.range(of: usernamePattern, options: .regularExpression) == nil
        {
            emailError = "Enter a valid email or username"
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
        // 401 → invalid credentials: surface both as an inline field error and
        // as the top-level alert.
        if case let NetworkError.httpError(statusCode, _) = error, statusCode == 401 {
            passwordError = "Invalid credentials"
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
