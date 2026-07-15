//
//  DeleteAccountViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class DeleteAccountViewModel: ObservableObject {

    // MARK: Flow state
    @Published var step: DeleteAccountStep

    // MARK: Feedback form state
    @Published var selectedReason: DeleteAccountReason?
    @Published var additionalComments: String
    @Published var password: String {
        didSet { if oldValue != password { passwordError = nil } }
    }

    // MARK: Submission state
    @Published var isDeleting: Bool
    /// Inline error under the password field — 401/403 wrong-password path.
    @Published var passwordError: String?
    /// Top-level alert message for non-field failures (network / server / 429).
    @Published var deletionError: String?

    let reasons: [DeleteAccountReason]

    private let api: ClickMeAPI

    init(
        step: DeleteAccountStep = .confirmation,
        selectedReason: DeleteAccountReason? = nil,
        additionalComments: String = "",
        password: String = "",
        isDeleting: Bool = false,
        reasons: [DeleteAccountReason] = DeleteAccountReason.allCases,
        api: ClickMeAPI = .shared
    ) {
        self.step = step
        self.selectedReason = selectedReason
        self.additionalComments = additionalComments
        self.password = password
        self.isDeleting = isDeleting
        self.reasons = reasons
        self.api = api
    }

    // MARK: Derived

    /// Enable the primary CTA on Step 2 only when the user has picked a
    /// reason and entered *something* for a password. Server rules are
    /// verified against a live call — this is just the client-side gate.
    var canConfirmDeletion: Bool {
        !isDeleting
        && selectedReason != nil
        && !password.isEmpty
    }

    // MARK: Step 1 → Step 2

    func advanceToFeedback() {
        withAnimation { step = .feedback }
    }

    // MARK: Step 2 → Step 3 (real deletion)

    /// Runs the two-step delete flow:
    /// 1. `POST /user/account/delete-request` with the entered password →
    ///    receive a single-use 15-min `deletion_token`.
    /// 2. `DELETE /user/account` with the token + reason + optional
    ///    write-in comments → account gone.
    /// On success we transition to the farewell screen. Session teardown
    /// (`UserManager.logout()`) is deferred to the farewell's "Back to
    /// Login" button so the user actually gets to see it — logging out
    /// immediately would trigger the app-level router to snap to Login and
    /// bypass the farewell entirely.
    func confirmDeletion() async {
        deletionError = nil
        passwordError = nil

        guard let reason = selectedReason else {
            deletionError = "Please choose a reason before continuing."
            return
        }
        guard !password.isEmpty else {
            passwordError = "Please enter your password to confirm."
            return
        }

        withAnimation { isDeleting = true }
        defer { isDeleting = false }

        let deletionToken: String
        do {
            let response = try await api.requestAccountDeletion(password: password)
            deletionToken = response.data.deletionToken
        } catch {
            handle(requestError: error)
            return
        }

        do {
            let trimmedComments = additionalComments.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await api.deleteAccount(
                deletionToken: deletionToken,
                reasonCategory: reason.wireKey,
                feedbackDetails: trimmedComments.isEmpty ? nil : trimmedComments,
                confirmPermanentAction: true
            )
        } catch {
            handle(deleteError: error)
            return
        }

        withAnimation { step = .deleted }
    }

    // MARK: Error mapping

    private func handle(requestError error: Error) {
        guard case let NetworkError.httpError(statusCode, data) = error else {
            deletionError = Self.message(for: error)
            return
        }

        switch statusCode {
        case 401, 403:
            passwordError = Self.decodeStandardMessage(from: data)
                ?? "Password is incorrect."
        case 429:
            deletionError = "Too many attempts. Please try again in a moment."
        default:
            deletionError = Self.decodeStandardMessage(from: data)
                ?? "Couldn't verify your password. Please try again."
        }
    }

    private func handle(deleteError error: Error) {
        guard case let NetworkError.httpError(statusCode, data) = error else {
            deletionError = Self.message(for: error)
            return
        }

        switch statusCode {
        case 400:
            // INVALID_TOKEN — 15-min token expired or already used. Rare in
            // practice because the two calls fire back-to-back, but if it
            // happens the user needs to re-enter their password to mint a
            // fresh one.
            passwordError = "That took too long. Please enter your password and try again."
        case 429:
            deletionError = "Too many attempts. Please try again in a moment."
        default:
            deletionError = Self.decodeStandardMessage(from: data)
                ?? "Couldn't delete your account. Please try again."
        }
    }

    private static func decodeStandardMessage(from data: Data) -> String? {
        (try? JSONDecoder().decode(StandardErrorResponse.self, from: data))?.message
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
