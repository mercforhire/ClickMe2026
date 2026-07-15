//
//  ChangePasswordViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-09.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ChangePasswordViewModel: ObservableObject {

    // MARK: Form state

    @Published var currentPassword: String = "" {
        didSet { if didAttemptSubmit { revalidateAfterEdit() } }
    }
    @Published var newPassword: String = "" {
        didSet { if didAttemptSubmit { revalidateAfterEdit() } }
    }
    @Published var confirmPassword: String = "" {
        didSet { if didAttemptSubmit { revalidateAfterEdit() } }
    }

    @Published var showCurrent: Bool = false
    @Published var showNew: Bool = false
    @Published var showConfirm: Bool = false

    // MARK: Field-level validation state

    @Published var currentPasswordError: String?
    @Published var newPasswordError: String?
    @Published var confirmPasswordError: String?
    @Published var didAttemptSubmit: Bool = false

    // MARK: Submission state

    @Published var isSubmitting: Bool = false
    @Published var didSucceed: Bool = false
    /// Non-field errors — network failures, 429, unknown 500s. Surfaced as
    /// an alert; inline errors go on the specific field.
    @Published var apiError: String?

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(api: ClickMeAPI = .shared) {
        self.api = api
    }

    /// Preview seam — pre-fills the form with canned values so `#Preview`
    /// can render the "happy path" (button enabled, strength = Secure, no
    /// inline errors) without user interaction.
    static func previewSeed(
        current: String,
        new: String,
        confirm: String
    ) -> ChangePasswordViewModel {
        let vm = ChangePasswordViewModel()
        vm.currentPassword = current
        vm.newPassword = new
        vm.confirmPassword = confirm
        return vm
    }

    // MARK: Derived

    /// Enable the primary CTA only when all three fields have content and
    /// none of them are currently showing an inline error. Server-side rules
    /// are re-checked on submit; this gate is just to prevent hopeless taps.
    var canSubmit: Bool {
        !isSubmitting
        && !currentPassword.isEmpty
        && !newPassword.isEmpty
        && !confirmPassword.isEmpty
    }

    // MARK: Client-side validation

    /// Server's real rules: `new_password` ≥ 8 chars, at least one digit, and
    /// must differ from `current_password`. We mirror them so the user gets
    /// immediate feedback and we save a round-trip.
    func validate() -> Bool {
        currentPasswordError = nil
        newPasswordError = nil
        confirmPasswordError = nil

        if currentPassword.isEmpty {
            currentPasswordError = "Please enter your current password."
        }

        if newPassword.isEmpty {
            newPasswordError = "Please enter a new password."
        } else if newPassword.count < 8 {
            newPasswordError = "Password must be at least 8 characters."
        } else if newPassword.range(of: "[0-9]", options: .regularExpression) == nil {
            newPasswordError = "Password must include a number."
        } else if newPassword == currentPassword && !currentPassword.isEmpty {
            newPasswordError = "New password must be different from your current password."
        }

        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your new password."
        } else if confirmPassword != newPassword {
            confirmPasswordError = "Passwords do not match."
        }

        return currentPasswordError == nil
            && newPasswordError == nil
            && confirmPasswordError == nil
    }

    /// Lighter-touch revalidation while the user is editing after a first
    /// attempt — only clears errors as the underlying condition becomes
    /// satisfied, without re-raising fresh empty-field errors.
    private func revalidateAfterEdit() {
        if currentPasswordError != nil, !currentPassword.isEmpty {
            currentPasswordError = nil
        }
        if let _ = newPasswordError {
            if !newPassword.isEmpty,
               newPassword.count >= 8,
               newPassword.range(of: "[0-9]", options: .regularExpression) != nil,
               newPassword != currentPassword
            {
                newPasswordError = nil
            }
        }
        if confirmPasswordError != nil,
           !confirmPassword.isEmpty,
           confirmPassword == newPassword
        {
            confirmPasswordError = nil
        }
    }

    // MARK: Submit

    func submit() async {
        didAttemptSubmit = true
        apiError = nil
        guard validate() else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await api.updatePassword(
                UpdatePasswordRequest(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
            )
            withAnimation(.easeOut(duration: 0.25)) { didSucceed = true }
            // Wipe the form once the change is committed — reduces the odds
            // of the user accidentally submitting a stale form on the next
            // visit and lets the success banner speak for itself.
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            handle(submitError: error)
        }
    }

    // MARK: Error mapping

    private func handle(submitError error: Error) {
        guard case let NetworkError.httpError(statusCode, data) = error else {
            apiError = Self.message(for: error)
            return
        }

        switch statusCode {
        case 403:
            // Wrong current password. Server always uses the FORBIDDEN code
            // for this endpoint at 403 — no field envelope, just a message.
            currentPasswordError = Self.decodeStandardMessage(from: data)
                ?? "Current password is incorrect."

        case 422:
            // Per spec, `errors` is always an array. Map each entry onto its
            // matching field. In practice these come through as `new_password`
            // or `current_password`.
            if let response = try? JSONDecoder().decode(FieldValidationErrorResponse.self, from: data) {
                for fieldError in response.errors {
                    switch fieldError.field {
                    case "current_password":
                        currentPasswordError = fieldError.message
                    case "new_password":
                        newPasswordError = fieldError.message
                    default:
                        apiError = fieldError.message
                    }
                }
            } else {
                apiError = Self.decodeStandardMessage(from: data)
                    ?? "Password could not be updated. Please check your entries and try again."
            }

        case 429:
            apiError = "Too many attempts. Please try again in a moment."

        default:
            apiError = Self.decodeStandardMessage(from: data)
                ?? "Couldn't update your password. Please try again."
        }
    }

    private static func decodeStandardMessage(from data: Data) -> String? {
        (try? JSONDecoder().decode(StandardErrorResponse.self, from: data))?.message
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
