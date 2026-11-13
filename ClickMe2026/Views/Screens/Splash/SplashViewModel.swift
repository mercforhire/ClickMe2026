//
//  SplashViewModel.swift
//  ClickMe2026
//
//  Attempts to restore the persisted session while the splash animation
//  plays. Resolves a `SplashDestination` that the parent can use to route
//  to the login screen or the appropriate home mode.
//

import Foundation
import Observation

enum SplashDestination: Equatable {
    case login
    /// Auto-login succeeded and the user is ready to land on a home
    /// screen. The associated `AppMode` reflects the landing decision:
    /// `.expert` only when the user is an expert AND has ≥1 topic;
    /// otherwise `.client` (safe default that always works).
    case dashboard(AppMode)
    /// Auto-login succeeded but the expert never completed the signup
    /// flow (`setup_completed=false` on `GET /expert/profile`). The app
    /// drops them back into the signup flow at Overview instead of
    /// routing to a half-empty expert home.
    case setupIncomplete
}

@MainActor
@Observable
final class SplashViewModel {
    private let userManager: UserManager
    private let displaySeconds: TimeInterval

    private(set) var destination: SplashDestination?

    init(
        userManager: UserManager = .shared,
        displaySeconds: TimeInterval = 3.0
    ) {
        self.userManager = userManager
        self.displaySeconds = displaySeconds
    }

    /// Shows the splash for `displaySeconds`, then checks the user manager and
    /// populates `destination` so the view can transition.
    ///
    /// Offline-tolerant: when `tryAutoLogin` succeeds in the "transient
    /// failure" branch (token still stored, `/me` unreachable), `me` is
    /// still nil here. Rather than kicking the user to login, we fall
    /// through to the dashboard using the persisted mode preference —
    /// the user keeps their session and the app hydrates cached profile
    /// data. The first successful authed request later re-populates
    /// `me` from the server.
    func start() async {
        try? await Task.sleep(nanoseconds: UInt64(displaySeconds * 1_000_000_000))

        let succeeded = await userManager.tryAutoLogin()
        guard succeeded else {
            destination = .login
            return
        }

        // Transient-failure branch: `tryAutoLogin` kept the token but
        // couldn't fetch `/me`. Honor the last-known mode preference
        // and skip the landing decision (which needs the account's roles).
        guard let roles = userManager.me?.roles else {
            destination = .dashboard(userManager.currentMode)
            return
        }

        // The shared landing decision (also used by Login): an expert with
        // unfinished setup resumes it, anything else lands on a home. It
        // makes no expert lookup for a client-only account in Client mode.
        switch await userManager.resolvePostAuthLanding(roles: roles) {
        case .setupHub:
            destination = .setupIncomplete
        case let .home(mode):
            destination = .dashboard(mode)
        }
    }
}
