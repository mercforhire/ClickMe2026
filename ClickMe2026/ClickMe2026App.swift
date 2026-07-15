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
                    if route == .clientHome || route == .expertHome {
                        route = .login
                    }
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
                case let .dashboard(role):
                    route = role == .expert ? .expertHome : .clientHome
                }
            }
        case .login:
            LoginView { role in
                route = role == .expert ? .expertHome : .clientHome
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
    case clientHome
    case expertHome
}
