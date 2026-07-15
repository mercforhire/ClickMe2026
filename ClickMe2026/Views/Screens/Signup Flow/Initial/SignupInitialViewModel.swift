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
    @Published var apiError: String?

    // MARK: Dependencies
    private let accumulator: SignupAccumulator?
    private let userManager: UserManager?

    init(
        username: String = "",
        email: String = "",
        password: String = "",
        usernameError: String? = nil,
        emailError: String? = nil,
        passwordError: String? = nil,
        didAttemptContinue: Bool = false,
        isLoading: Bool = false,
        accumulator: SignupAccumulator? = nil,
        userManager: UserManager? = nil
    ) {
        self.username = username
        self.email = email
        self.password = password
        self.usernameError = usernameError
        self.emailError = emailError
        self.passwordError = passwordError
        self.didAttemptContinue = didAttemptContinue
        self.isLoading = isLoading
        self.accumulator = accumulator
        self.userManager = userManager
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

    /// Validates the form, POSTs `/auth/signup`, stashes the returned bearer
    /// token via `UserManager`, and mirrors credentials onto the accumulator.
    /// Sets `isComplete` on success so the view can navigate. When no
    /// `userManager` is wired (preview / test path) the network call is
    /// skipped and `isComplete` fires immediately.
    func attemptContinue() {
        didAttemptContinue = true
        validateUsername()
        validateEmail()
        validatePassword()
        guard usernameError == nil, emailError == nil, passwordError == nil else { return }

        // Mirror credentials onto the accumulator so downstream screens have
        // access to the email (verify screen) without prop drilling.
        accumulator?.username = username
        accumulator?.email = email
        accumulator?.password = password

        guard let userManager else {
            // Preview / test path: skip the network call.
            isComplete = true
            return
        }

        apiError = nil
        isLoading = true
        Task { [self] in
            defer { isLoading = false }
            do {
                _ = try await userManager.signup(
                    username: username,
                    email: email,
                    password: password,
                    role: .expert
                )
                isComplete = true
            } catch {
                handle(signupError: error)
            }
        }
    }

    // MARK: Helpers

    private func handle(signupError error: Error) {
        // 409 Conflict → username/email already taken. Surface as an inline
        // field error so the user can correct it in place.
        if case let NetworkError.httpError(statusCode, data) = error,
           statusCode == 409,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            let message = response.message
            if message.localizedCaseInsensitiveContains("username") {
                usernameError = message
            } else {
                emailError = message
            }
            return
        }
        apiError = Self.message(for: error)
    }

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
