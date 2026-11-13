//
//  ClickMe2026App.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI
import UIKit

@main
struct ClickMe2026App: App {
    @UIApplicationDelegateAdaptor var appDelegate: ClickMe2026AppDelegate
    @State private var userManager = UserManager.shared
    @State private var route: AppRoute = .splash
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            content
                .keyboardDismissToolbar()
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
                // The Expert gate found the expert's setup unfinished: open
                // the setup hub. `currentMode` is unchanged, so the mirror
                // above does not fight this, and only a home route hands
                // off (never from splash, login or the hub itself). The hub
                // hydrates from the profile the gate just fetched; the
                // request is only raised after a successful lookup.
                .onChange(of: userManager.setupHubRequested) { _, requested in
                    guard requested else { return }
                    userManager.consumeSetupHubRequest()
                    guard route == .clientHome || route == .expertHome else { return }
                    route = .signupSetup
                }
                // D-02: a setup lookup that failed at launch or login is retried
                // when the app comes back to the foreground, only on a home
                // route. The re-check is role-guarded and makes no request
                // for a client-only account. If a device check shows this
                // App-level phase does not report `.active` (RESEARCH A6),
                // move the call into the two home shells' existing
                // `scenePhase` handlers instead.
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    guard route == .clientHome || route == .expertHome else { return }
                    Task { await userManager.recheckSetupIfPending() }
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
