//
//  SignupVerifyEmailViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupVerifyEmailViewModel: ObservableObject {

    let email: String

    // MARK: Code entry
    /// Digits typed by the user. Sanitized on every keystroke — non-digits
    /// stripped and length capped at 6.
    @Published var code: String = ""
    @Published var codeError: String?

    // MARK: Resend state
    @Published var isResending: Bool = false
    @Published var didResend: Bool = false
    @Published var resendCooldown: Int = 0
    @Published var resendError: String?

    // MARK: Verify state
    /// Set `true` once `POST /auth/email/verify` returns 200. The parent
    /// orchestrator observes this to advance the flow.
    @Published private(set) var isVerified: Bool = false
    @Published var isVerifying: Bool = false

    // MARK: Dependencies
    private let api: ClickMeAPI?
    private let accumulator: SignupAccumulator?

    private var cooldownTask: Task<Void, Never>?

    init(
        email: String = "lucas.anderson@example.com",
        code: String = "",
        codeError: String? = nil,
        isResending: Bool = false,
        didResend: Bool = false,
        resendCooldown: Int = 0,
        accumulator: SignupAccumulator? = nil,
        api: ClickMeAPI? = nil
    ) {
        self.email = email
        self.code = code
        self.codeError = codeError
        self.isResending = isResending
        self.didResend = didResend
        self.resendCooldown = resendCooldown
        self.accumulator = accumulator
        self.api = api
    }

    /// Runtime init — reads the email from the accumulator and enables
    /// network-backed resend + verify.
    convenience init(accumulator: SignupAccumulator, api: ClickMeAPI = .shared) {
        self.init(
            email: accumulator.email,
            accumulator: accumulator,
            api: api
        )
    }

    deinit {
        cooldownTask?.cancel()
    }

    // MARK: - Code sanitization

    /// Strips non-digits, caps at 6 characters, and clears any lingering
    /// inline error. Wire to the field's `onChange` in the view.
    func codeDidChange() {
        let digits = code.filter(\.isNumber)
        let clipped = String(digits.prefix(6))
        if clipped != code { code = clipped }
        if codeError != nil { codeError = nil }
    }

    // MARK: - Verify

    /// Submits the 6-digit code to `POST /auth/email/verify`. Flips
    /// `isVerified` + `accumulator.emailVerified` on success. Sets
    /// `codeError` on 422 so the field can highlight inline.
    func verify() async {
        guard !isVerifying else { return }
        guard code.count == 6 else {
            codeError = "Code must be 6 digits"
            return
        }

        // Preview / test path — no network, canned success.
        guard let api else {
            isVerifying = true
            try? await Task.sleep(for: .seconds(0.6))
            isVerifying = false
            isVerified = true
            accumulator?.emailVerified = true
            return
        }

        codeError = nil
        isVerifying = true
        defer { isVerifying = false }
        do {
            _ = try await api.verifyEmailCode(VerifyEmailCodeRequest(code: code))
            isVerified = true
            accumulator?.emailVerified = true
        } catch {
            // Server returns a user-facing message on 422/INVALID_CODE
            // ("Invalid or expired code. Please request a new one.") —
            // surface it inline on the field. Any other transient error
            // (offline, 5xx) uses the same slot; the user can retry.
            codeError = error.userMessage
        }
    }

    // MARK: - Resend

    func resend() async {
        guard !isResending, resendCooldown == 0 else { return }

        // Preview / test path — no network, canned success animation.
        guard let api else {
            isResending = true
            try? await Task.sleep(for: .seconds(1.0))
            isResending = false
            didResend = true
            startCooldown(seconds: 30)
            return
        }

        resendError = nil
        isResending = true
        defer { isResending = false }
        do {
            _ = try await api.resendVerificationEmail()
            didResend = true
            // A fresh code invalidates any previously-typed digits — clear
            // the field so the user doesn't submit the stale code.
            code = ""
            codeError = nil
            startCooldown(seconds: 30)
        } catch {
            resendError = error.userMessage
        }
    }

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()
        resendCooldown = seconds
        cooldownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, self.resendCooldown > 0 else { return }
                self.resendCooldown -= 1
            }
        }
    }
}
