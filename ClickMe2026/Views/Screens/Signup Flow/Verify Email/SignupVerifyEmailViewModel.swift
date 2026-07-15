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

    // MARK: Resend state
    @Published var isResending: Bool = false
    @Published var didResend: Bool = false
    @Published var resendCooldown: Int = 0
    @Published var resendError: String?

    // MARK: Polling state
    /// Flipped `true` when `GET /auth/email/status` returns `verified=true`.
    /// The parent orchestrator observes this to advance the flow.
    @Published private(set) var isVerified: Bool = false

    // MARK: Dependencies
    private let api: ClickMeAPI?
    private let accumulator: SignupAccumulator?

    private var cooldownTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?

    /// Interval between `GET /auth/email/status` polls. 5s per the backend
    /// spec — cheap read, but fast enough that "the user just clicked the
    /// link" feels responsive.
    private static let pollInterval: Duration = .seconds(5)

    init(
        email: String = "lucas.anderson@example.com",
        isResending: Bool = false,
        didResend: Bool = false,
        resendCooldown: Int = 0,
        accumulator: SignupAccumulator? = nil,
        api: ClickMeAPI? = nil
    ) {
        self.email = email
        self.isResending = isResending
        self.didResend = didResend
        self.resendCooldown = resendCooldown
        self.accumulator = accumulator
        self.api = api
    }

    /// Runtime init — reads the email from the accumulator and enables
    /// network-backed resend + polling.
    convenience init(accumulator: SignupAccumulator, api: ClickMeAPI = .shared) {
        self.init(
            email: accumulator.email,
            accumulator: accumulator,
            api: api
        )
    }

    deinit {
        cooldownTask?.cancel()
        pollTask?.cancel()
    }

    // MARK: - Polling

    /// Starts (or restarts) the poll loop. Idempotent — safe to call from
    /// `.task {}` on every appearance.
    func startPolling() {
        guard api != nil else { return }
        guard !isVerified else { return }
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollOnce()
                if self?.isVerified == true { return }
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func pollOnce() async {
        guard let api else { return }
        do {
            let response = try await api.checkEmailVerified()
            if response.data.verified {
                isVerified = true
                accumulator?.emailVerified = true
            }
        } catch {
            // Silently ignore transient poll failures — the next tick will
            // retry. Surfacing every timeout would be noise.
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
            startCooldown(seconds: 30)
        } catch {
            resendError = Self.errorMessage(for: error)
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

    // MARK: - Error mapping

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
