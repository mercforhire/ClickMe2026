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
    @Published var successMessage: String?

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
            emailError = "Please enter your email or username"
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

    func attemptSend() async {
        didAttemptSend = true
        validateEmail()
        guard emailError == nil else { return }

        apiError = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        let identity = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let response = try await api.forgotPassword(identity: identity)
            successMessage = response.message
            isSent = true
        } catch {
            apiError = Self.message(for: error)
        }
    }

    // MARK: Helpers

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
