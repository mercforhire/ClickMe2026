//
//  SplashViewModel.swift
//  ClickMe2026
//
//  Attempts to restore the persisted session while the splash animation
//  plays. Resolves a `SplashDestination` that the parent can use to route
//  to the login screen or the appropriate role-specific dashboard.
//

import Foundation
import Observation

enum SplashDestination: Equatable {
    case login
    case dashboard(UserRole)
}

@MainActor
@Observable
final class SplashViewModel {
    private let userManager: UserManager
    private let minimumDisplaySeconds: TimeInterval

    private(set) var destination: SplashDestination?

    init(
        userManager: UserManager = .shared,
        minimumDisplaySeconds: TimeInterval = 2.2
    ) {
        self.userManager = userManager
        self.minimumDisplaySeconds = minimumDisplaySeconds
    }

    /// Runs the auth check and enforces the minimum splash display time.
    /// When both complete, `destination` is populated so the view can transition.
    func start() async {
        let startedAt = Date()
        let succeeded = await userManager.tryAutoLogin()

        let elapsed = Date().timeIntervalSince(startedAt)
        let remaining = max(0, minimumDisplaySeconds - elapsed)
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        if succeeded, let role = userManager.me?.role {
            destination = .dashboard(role)
        } else {
            destination = .login
        }
    }
}
