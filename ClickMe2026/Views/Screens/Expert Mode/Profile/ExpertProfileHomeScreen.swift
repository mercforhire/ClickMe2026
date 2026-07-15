//
//  ExpertProfileHomeScreen.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-12.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Route

/// Push targets from the expert profile hub. Kept as an enum so the whole
/// list is visible in one place and unimplemented rows show a placeholder
/// stub rather than crashing.
private enum ExpertProfileHomeRoute: Hashable {
    /// Edit-profile route — reached via the pencil on the user card.
    case personalInfo
    // Professional
    case expertiseTopics
    case availability
    case payouts
    // Account
    case security
    // Preferences
    case notifications
    case privacy
    // Support
    case faq
    case feedback
}

// MARK: - Screen

/// The expert-side profile hub. Mirrors `ClientProfileHomeScreen` — same
/// design tokens, same list/row components — with an expert-specific
/// "Professional" section (Expertise & Topics, Availability, Payouts).
struct ExpertProfileHomeScreen: View {

    @StateObject private var viewModel: ExpertProfileHomeViewModel

    @State private var path: [ExpertProfileHomeRoute] = []
    @State private var showLogoutConfirmation: Bool = false

    // MARK: Inits

    init(viewModel: ExpertProfileHomeViewModel = ExpertProfileHomeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ClientProfileHomeBrand.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        userCard

                        section(title: "Professional") {
                            row(icon: "brain.head.profile", title: "Expertise & Topics") {
                                path.append(.expertiseTopics)
                            }
                            row(icon: "calendar", title: "Availability") {
                                path.append(.availability)
                            }
                            row(icon: "banknote.fill", title: "Payouts & Earnings") {
                                path.append(.payouts)
                            }
                        }

                        section(title: "Account") {
                            row(icon: "lock.fill", title: "Security & Password") {
                                path.append(.security)
                            }
                        }

                        section(title: "Preferences") {
                            row(icon: "bell.fill", title: "Notifications") {
                                path.append(.notifications)
                            }
                            row(icon: "eye.fill", title: "Privacy") {
                                path.append(.privacy)
                            }
                        }

                        section(title: "Support") {
                            row(icon: "questionmark.circle.fill", title: "FAQ & Help") {
                                path.append(.faq)
                            }
                            row(icon: "exclamationmark.bubble.fill", title: "Send Feedback") {
                                path.append(.feedback)
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
            .navigationTitle("Expert Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ClientProfileHomeBrand.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: ExpertProfileHomeRoute.self) { route in
                destination(for: route)
            }
        }
        .task { await viewModel.loadHeader() }
        .confirmationDialog(
            "Log out of ClickMe?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                viewModel.logOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - User card

    private var userCard: some View {
        ClientProfileHomeUserCard(
            name: viewModel.name.isEmpty ? "Your Profile" : viewModel.name,
            email: viewModel.email,
            avatarURL: viewModel.avatarURL,
            isOnline: viewModel.isOnline,
            onEditTap: { path.append(.personalInfo) }
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
    private func destination(for route: ExpertProfileHomeRoute) -> some View {
        switch route {
        case .personalInfo:
            ExpertProfileSettingsView()
        case .expertiseTopics:
            TopicsSetupView()
        case .availability:
            AvailabilitySettingsView()
        case .payouts:
            PayoutsView()
        case .security:
            AccountSecurityView()
        case .notifications:
            NotificationSettingsView()
        case .privacy:
            placeholder(title: "Privacy")
        case .faq:
            HelpView()
        case .feedback:
            FeedbackView()
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

#Preview("Expert Profile Hub") {
    ExpertProfileHomeScreen(viewModel: .previewSeed())
        .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return ExpertProfileHomeScreen()
        .preferredColorScheme(.dark)
}
