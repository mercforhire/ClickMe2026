//
//  LoginForgetPassViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class LoginForgetPassViewModel: ObservableObject {

    // MARK: Form state
    @Published var email: String

    // MARK: Validation state
    @Published var emailError: String?
    @Published var didAttemptSend: Bool

    // MARK: Submission state
    @Published var isLoading: Bool = false
    @Published var isSent: Bool = false

    // MARK: API feedback
    @Published var apiError: String?

    private let api: ClickMeAPI

    init(
        email: String = "",
        emailError: String? = nil,
        didAttemptSend: Bool = false,
        isSent: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.email = email
        self.emailError = emailError
        self.didAttemptSend = didAttemptSend
        self.isSent = isSent
        self.api = api
    }

    // MARK: Validation

    func validateEmail() {
        let pattern = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        if email.isEmpty {
            emailError = "Please enter your email"
        } else if email.range(of: pattern, options: .regularExpression) == nil {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }

    /// Revalidate the email field after edits, once a send has been attempted.
    func emailDidChange() {
        if didAttemptSend { validateEmail() }
    }

    // MARK: Submit

    /// Sends a password-reset request. On success (or when the server chooses
    /// not to disclose whether the account exists) flips `isSent` so callers
    /// can navigate onward to the code-entry / new-password step. On failure
    /// populates `apiError`; field errors are also surfaced inline on
    /// `emailError`.
    ///
    /// - Returns: the trimmed identity the user submitted, if the request was
    ///   accepted. The caller uses this to seed the next screen's email.
    @discardableResult
    func attemptSend() async -> String? {
        didAttemptSend = true
        validateEmail()
        guard emailError == nil else { return nil }

        apiError = nil
        isLoading = true
        defer { isLoading = false }

        let identity = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await api.forgotPassword(identity: identity)
            isSent = true
            return identity
        } catch {
            handle(sendError: error)
            return nil
        }
    }

    // MARK: Helpers

    private func handle(sendError error: Error) {
        // If the server flagged the identity field specifically, surface it
        // inline. Otherwise fall through to the alert.
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(FieldValidationErrorResponse.self, from: data),
           let identityError = response.errors.first(where: { $0.field == "identity" || $0.field == "email" })
        {
            emailError = identityError.message
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
