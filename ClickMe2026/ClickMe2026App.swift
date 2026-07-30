//
//  ClickMe2026App.swift
//  ClickMe2026
//
//  Copyright © 2024 Q42. All rights reserved.
//

import SwiftUI

@main
struct ClickMe2026App: App {
    @UIApplicationDelegateAdaptor var appDelegate: ClickMe2026AppDelegate
    @StateObject private var userManager = UserManager.shared
    @State private var route: AppRoute = .splash

    var body: some Scene {
        WindowGroup {
            content
                // Whenever the auth state flips to logged-out from a
                // logged-in screen, snap back to the login route. This is
                // how `UserManager.logout()` becomes user-visible.
                .onChange(of: userManager.isLoggedIn) { _, isLoggedIn in
                    guard !isLoggedIn else { return }
                    if route == .clientHome || route == .expertHome || route == .signupSetup {
                        route = .login
                    }
                }
                // Mirror `currentMode` onto the route so a switch from
                // ModeSwitchView (or a background→resume) immediately
                // re-renders the correct home. Only applies while the
                // user is currently on a home route — splash / login /
                // signup flows manage their own transitions.
                .onChange(of: userManager.currentMode) { _, newMode in
                    guard route == .clientHome || route == .expertHome else { return }
                    route = newMode == .expert ? .expertHome : .clientHome
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .splash:
            SplashScreenView { destination in
                switch destination {
                case .login:
                    route = .login
                case let .dashboard(mode):
                    route = mode == .expert ? .expertHome : .clientHome
                case .setupIncomplete:
                    route = .signupSetup
                }
            }
        case .login:
            LoginView { mode in
                route = mode == .expert ? .expertHome : .clientHome
            }
        case .signupSetup:
            // Auto-logged-in expert whose profile setup never finished —
            // start LoginView already pushed into the signup flow at
            // Overview so they can pick up where they left off.
            // Pass the freshly-refreshed expert profile so every field
            // already persisted server-side (basic info, avatar,
            // languages, timezone, hourly rate, expertise tags)
            // pre-fills instead of asking the user to redo them.
            LoginView(
                startAtSignupSetup: true,
                hydrateFrom: userManager.expertProfile
            ) { mode in
                route = mode == .expert ? .expertHome : .clientHome
            }
        case .clientHome:
            HomeClientView()
        case .expertHome:
            HomeExpertView()
        }
    }
}

private enum AppRoute {
    case splash
    case login
    case signupSetup
    case clientHome
    case expertHome
}
