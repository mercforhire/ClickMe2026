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
        userManager: UserManager = .shared
    ) {
        self.email = email
        self.password = password
        self.emailError = emailError
        self.passwordError = passwordError
        self.didAttemptLogin = didAttemptLogin
        self.userManager = userManager
    }

    // MARK: Validation

    func validateEmail() {
        let pattern = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        if email.isEmpty {
            emailError = nil
        } else if email.range(of: pattern, options: .regularExpression) == nil {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }

    func validatePassword() {
        if password.isEmpty {
            passwordError = nil
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

    func attemptLogin() async {
        didAttemptLogin = true
        validateEmail()
        validatePassword()
        guard emailError == nil, passwordError == nil,
              !email.isEmpty, !password.isEmpty else { return }

        apiError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await userManager.login(email: email, password: password)
        } catch {
            apiError = Self.message(for: error)
        }
    }

    // MARK: Helpers

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
