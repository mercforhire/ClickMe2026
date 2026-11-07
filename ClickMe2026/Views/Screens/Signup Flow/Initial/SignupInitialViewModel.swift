//
//  SignupInitialViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupInitialViewModel: ObservableObject {

    // MARK: Form state
    @Published var email: String
    @Published var password: String

    // MARK: Validation state
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
        email: String = "",
        password: String = "",
        emailError: String? = nil,
        passwordError: String? = nil,
        didAttemptContinue: Bool = false,
        isLoading: Bool = false,
        accumulator: SignupAccumulator? = nil,
        userManager: UserManager? = nil
    ) {
        self.email = email
        self.password = password
        self.emailError = emailError
        self.passwordError = passwordError
        self.didAttemptContinue = didAttemptContinue
        self.isLoading = isLoading
        self.accumulator = accumulator
        self.userManager = userManager
    }

    // MARK: Validation

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
        } else if password.range(of: "[A-Za-z]", options: .regularExpression) == nil {
            // Backend requires at least one letter — mirror the rule client-side
            // so users see the error before the round trip.
            passwordError = "Password must contain at least one letter"
        } else {
            passwordError = nil
        }
    }

    /// Revalidate each field after edits, once a continue has been attempted.
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
        validateEmail()
        validatePassword()
        guard emailError == nil, passwordError == nil else { return }

        // Mirror credentials onto the accumulator so downstream screens have
        // access to the email (verify screen) without prop drilling.
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
        guard case let NetworkError.httpError(statusCode, data) = error else {
            apiError = Self.message(for: error)
            return
        }

        // 409 Conflict → email already taken.
        if statusCode == 409,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            emailError = response.message
            return
        }

        // 422 Validation → per-field messages.
        if statusCode == 422,
           let response = try? JSONDecoder().decode(FieldValidationErrorResponse.self, from: data)
        {
            for fieldError in response.errors {
                switch fieldError.field {
                case "email":    emailError = fieldError.message
                case "password": passwordError = fieldError.message
                default:         apiError = fieldError.message
                }
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
