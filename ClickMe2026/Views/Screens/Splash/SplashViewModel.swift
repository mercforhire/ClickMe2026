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
    func start() async {
        try? await Task.sleep(nanoseconds: UInt64(displaySeconds * 1_000_000_000))

        let succeeded = await userManager.tryAutoLogin()
        guard succeeded, let roles = userManager.me?.roles else {
            destination = .login
            return
        }

        let isExpert = roles.contains(.expert)

        // For experts we need the authoritative `setup_completed` flag
        // to decide dashboard vs setup-resume. On error we default to
        // `false` so a transient network failure doesn't push
        // completed users back into signup.
        if isExpert {
            let incomplete = await isExpertProfileIncomplete()
            if incomplete {
                destination = .setupIncomplete
                return
            }
        }

        destination = .dashboard(await resolveLandingMode(isExpert: isExpert))
    }

    /// Landing decision.
    ///
    /// - **Restore branch.** If any mode was persisted from a prior
    ///   session — whether explicitly via `ModeSwitchView` or as the
    ///   first-boot compute below — we restore it as-is. No role or
    ///   topic guards here: `ModeSwitchView` allows either mode
    ///   regardless of role, so honoring persistence must too.
    ///   Cleared on `logout()`, so a fresh login always falls into the
    ///   smart-landing branch below.
    /// - **Smart-landing branch.** On the very first boot after login
    ///   (no stored preference), pick expert home only if the user is
    ///   an expert AND has ≥1 topic — otherwise client home. This
    ///   preserves the "empty expert dashboard is worse than client
    ///   home" safety guarantee for cold-launch first-time users.
    ///
    /// Either path calls `setMode` so the `ClickMe2026App` route
    /// observer stays in sync AND the choice is persisted for next
    /// cold launch.
    private func resolveLandingMode(isExpert: Bool) async -> AppMode {
        let mode: AppMode

        if userManager.hasStoredModePreference {
            mode = userManager.currentMode
        } else {
            let hasTopics = isExpert ? await userManager.expertHasTopics() : false
            mode = hasTopics ? .expert : .client
        }

        userManager.setMode(mode)
        return mode
    }

    private func isExpertProfileIncomplete() async -> Bool {
        do {
            try await userManager.refreshExpertProfile()
        } catch {
            return false
        }
        return userManager.expertProfile?.setupCompleted == false
    }
}
