//
//  ClientProfileHomeScreen.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-09.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Route

/// Push targets from the profile hub. Kept as an enum so the whole list is
/// visible in one place and unimplemented rows show a placeholder stub
/// rather than crashing.
private enum ClientProfileHomeRoute: Hashable {
    /// The edit-profile route — reached via the pencil on the user card and
    /// (in the past) via a "Personal Information" list row. We kept the case
    /// so the pencil still has a target after that list row was removed for
    /// being redundant with the pencil affordance.
    case personalInfo
    case savedExperts
    case security
    case notifications
    case payment
    case privacy
    case faq
    case feedback
    case modeSwitch
}

// MARK: - Screen

struct ClientProfileHomeScreen: View {

    @StateObject private var viewModel: ClientProfileHomeViewModel

    /// Push path is provided by the enclosing `HomeClientView` via
    /// `@Environment(\.homeNavigationPath)`. When rendered outside the
    /// shell (previews, tests) the fallback `_localPath` provides a
    /// self-contained NavigationStack so the screen still works.
    @Environment(\.homeNavigationPath) private var navPath
    @State private var _localPath: [ClientProfileHomeRoute] = []
    @State private var showLogoutConfirmation: Bool = false

    // MARK: Inits

    init(viewModel: ClientProfileHomeViewModel = ClientProfileHomeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        Group {
            if navPath != nil {
                screenWithDestinations
            } else {
                NavigationStack(path: $_localPath) {
                    screenWithDestinations
                }
            }
        }
        .task { await viewModel.loadHeader() }
        .confirmationDialog(
            "Log out of ClickMe?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                guard CallCenter.shared.attempt("log out") else { return }
                viewModel.logOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var screenWithDestinations: some View {
        ZStack {
            ClientProfileHomeBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    userCard

                    ClientProfileHomeModeSwitchCard(
                        action: { push(.modeSwitch) }
                    )

                    section(title: "Discovery") {
                        row(icon: "heart.fill", title: "Saved Experts") {
                            push(.savedExperts)
                        }
                    }

                    section(title: "Account") {
                        row(icon: "lock.fill", title: "Security & Password") {
                            push(.security)
                        }
                        row(icon: "creditcard.fill", title: "Payment") {
                            push(.payment)
                        }
                    }

                    section(title: "Preferences") {
                        row(icon: "bell.fill", title: "Notifications") {
                            push(.notifications)
                        }
                        row(icon: "eye.fill", title: "Privacy") {
                            push(.privacy)
                        }
                    }

                    section(title: "Support") {
                        row(icon: "questionmark.circle.fill", title: "FAQ & Help") {
                            push(.faq)
                        }
                        row(icon: "exclamationmark.bubble.fill", title: "Send Feedback") {
                            push(.feedback)
                        }
                    }

                    section(title: "Actions") {
                        ClientProfileHomeListItem(
                            icon: "arrow.right.square.fill",
                            title: "Log Out",
                            isDestructive: true,
                            action: { showLogoutConfirmation = true }
                        )
                    }

                    versionFooter
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClientProfileHomeBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: ClientProfileHomeRoute.self) { route in
            destination(for: route)
        }
    }

    private func push(_ route: ClientProfileHomeRoute) {
        if let navPath {
            navPath.push(route)
        } else {
            _localPath.append(route)
        }
    }

    // MARK: - User card

    private var userCard: some View {
        ClientProfileHomeUserCard(
            name: viewModel.name.isEmpty ? "Your Profile" : viewModel.name,
            email: viewModel.email,
            avatarURL: viewModel.avatarURL,
            isOnline: viewModel.isOnline,
            onEditTap: { push(.personalInfo) }
        )
    }

    // MARK: - Sections

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundColor(ClientProfileHomeBrand.sectionHeader)
                .opacity(0.80)
                .padding(.leading, 4)

            VStack(spacing: 8) {
                content()
            }
        }
    }

    private func row(icon: String, title: String, action: @escaping () -> Void) -> some View {
        ClientProfileHomeListItem(icon: icon, title: title, action: action)
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destination(for route: ClientProfileHomeRoute) -> some View {
        switch route {
        case .personalInfo:
            ClientProfileSettingsView()
        case .savedExperts:
            FavoritesView()
        case .security:
            placeholder(title: "Security & Password")
        case .notifications:
            NotificationSettingsView()
        case .payment:
            PaymentMethodsView()
        case .privacy:
            placeholder(title: "Privacy")
        case .faq:
            HelpView()
        case .feedback:
            FeedbackView()
        case .modeSwitch:
            ModeSwitchView { mode in
                // Block mode-switch mid-call — tearing down the client
                // socket + role context would kill the active session.
                guard CallCenter.shared.attempt("switch modes") else { return }
                // Flip the app's active home mode. ClickMe2026App
                // observes `currentMode` and snaps to the corresponding
                // home route immediately.
                UserManager.shared.setMode(mode)
            }
        }
    }

    private func placeholder(title: String) -> some View {
        ZStack {
            ClientProfileHomeBrand.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(ClientProfileHomeBrand.onSurfaceVar)
                Text("\(title) — coming soon")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(ClientProfileHomeBrand.onSurfaceVar)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Version footer

    private var versionFooter: some View {
        VStack(spacing: 6) {
            Text(Self.versionString)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ClientProfileHomeBrand.onSurfaceVar)
            Text("© 2026 ClickMe Innovations")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ClientProfileHomeBrand.onSurfaceVar.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
    }

    private static var versionString: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }
}

// MARK: - Previews

#Preview("Profile Hub") {
    ClientProfileHomeScreen(viewModel: .previewSeed())
        .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return ClientProfileHomeScreen()
        .preferredColorScheme(.dark)
}
