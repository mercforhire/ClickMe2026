//
//  SignupInitialViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupInitialViewModel: ObservableObject {

    // MARK: Form state
    @Published var username: String
    @Published var email: String
    @Published var password: String

    // MARK: Validation state
    @Published var usernameError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var didAttemptContinue: Bool

    // MARK: Submission state
    @Published var isLoading: Bool = false
    @Published var isComplete: Bool = false

    init(
        username: String = "",
        email: String = "",
        password: String = "",
        usernameError: String? = nil,
        emailError: String? = nil,
        passwordError: String? = nil,
        didAttemptContinue: Bool = false
    ) {
        self.username = username
        self.email = email
        self.password = password
        self.usernameError = usernameError
        self.emailError = emailError
        self.passwordError = passwordError
        self.didAttemptContinue = didAttemptContinue
    }

    // MARK: Validation

    func validateUsername() {
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            usernameError = "Username is required"
        } else if username.count < 3 {
            usernameError = "Username must be at least 3 characters"
        } else {
            usernameError = nil
        }
    }

    func validateEmail() {
        let pattern = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        if email.isEmpty {
            emailError = "Email is required"
        } else if email.range(of: pattern, options: .regularExpression) == nil {
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

    /// Revalidate each field after edits, once a continue has been attempted.
    func usernameDidChange() {
        if didAttemptContinue { validateUsername() }
    }

    func emailDidChange() {
        if didAttemptContinue { validateEmail() }
    }

    func passwordDidChange() {
        if didAttemptContinue { validatePassword() }
    }

    // MARK: Submit

    func attemptContinue() async {
        didAttemptContinue = true
        validateUsername()
        validateEmail()
        validatePassword()
        guard usernameError == nil, emailError == nil, passwordError == nil else { return }

        isLoading = true
        try? await Task.sleep(for: .seconds(0.8))
        isLoading = false
        isComplete = true
    }
}
