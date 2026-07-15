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
        if succeeded, let role = userManager.me?.role {
            destination = .dashboard(role)
        } else {
            destination = .login
        }
    }
}
