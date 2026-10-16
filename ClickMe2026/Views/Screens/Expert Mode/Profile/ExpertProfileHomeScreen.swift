//
//  ExpertProfileHomeScreen.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-12.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Route

/// Push targets from the expert profile hub. Kept as an enum so the whole
/// list is visible in one place and unimplemented rows show a placeholder
/// stub rather than crashing.
private enum ExpertProfileHomeRoute: Hashable {
    /// Edit-profile route — reached via the pencil on the user card.
    case personalInfo
    /// Read-only view of the expert's own public profile — same layout
    /// clients see when browsing them, including reviews.
    case myPublicProfile
    // Professional
    case expertiseTopics
    case availability
    case payouts
    /// Stripe Connect / CRA tax information — legal identity, address,
    /// DOB, TIN, financial account identifier. Backend: `/expert/tax-profile`.
    case taxProfile
    // Account
    case security
    // Preferences
    case notifications
    case privacy
    // Support
    case faq
    case feedback
    // Mode
    case modeSwitch
}

// MARK: - Screen

/// The expert-side profile hub. Mirrors `ClientProfileHomeScreen` — same
/// design tokens, same list/row components — with an expert-specific
/// "Professional" section (Expertise & Topics, Availability, Payouts).
struct ExpertProfileHomeScreen: View {

    @StateObject private var viewModel: ExpertProfileHomeViewModel

    /// Push path is provided by the enclosing `HomeExpertView` via
    /// `@Environment(\.homeNavigationPath)`. When rendered outside the
    /// shell (previews, tests) the fallback `_localPath` provides a
    /// self-contained NavigationStack so the screen still works.
    @Environment(\.homeNavigationPath) private var navPath
    @State private var _localPath: [ExpertProfileHomeRoute] = []
    @State private var showLogoutConfirmation: Bool = false

    // MARK: Inits

    init(viewModel: ExpertProfileHomeViewModel = ExpertProfileHomeViewModel()) {
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
        // `.alert` (not `.confirmationDialog`) so the prompt centers
        // on-screen everywhere. Confirmation dialogs render as
        // bottom action sheets on iPhone and as popovers anchored to
        // the source view on iPad — the latter can appear pinned to
        // the top or side of the screen depending on where the tap
        // originated. Alerts always render centered.
        .alert(
            "Log out of ClickMe?",
            isPresented: $showLogoutConfirmation
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

                    ExpertProfileHomeModeSwitchCard(
                        action: { push(.modeSwitch) }
                    )

                    section(title: "Professional") {
                        row(icon: "person.crop.circle.fill", title: "View My Public Profile") {
                            push(.myPublicProfile)
                        }
                        row(icon: "brain.head.profile", title: "Expertise & Topics") {
                            push(.expertiseTopics)
                        }
                        row(icon: "calendar", title: "Availability") {
                            push(.availability)
                        }
                        row(icon: "banknote.fill", title: "Payouts & Earnings") {
                            push(.payouts)
                        }
                        row(icon: "doc.text.fill", title: "Tax & Payout Info") {
                            push(.taxProfile)
                        }
                    }

                    section(title: "Account") {
                        row(icon: "lock.fill", title: "Security & Password") {
                            push(.security)
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
        .navigationTitle("Expert Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClientProfileHomeBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: ExpertProfileHomeRoute.self) { route in
            destination(for: route)
        }
    }

    private func push(_ route: ExpertProfileHomeRoute) {
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
                .font(.caption.weight(.semibold))
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
        case .myPublicProfile:
            myPublicProfileDestination
        case .expertiseTopics:
            TopicsSetupView()
        case .availability:
            AvailabilitySettingsView()
        case .payouts:
            PayoutsView()
        case .taxProfile:
            ExpertTaxProfileView()
        case .security:
            AccountSecurityView()
        case .notifications:
            NotificationSettingsView()
        case .privacy:
            SafariView(url: AppLinks.privacyPolicy)
                .ignoresSafeArea()
                .navigationTitle("Privacy")
                .navigationBarTitleDisplayMode(.inline)
        case .faq:
            HelpView()
        case .feedback:
            FeedbackView()
        case .modeSwitch:
            ModeSwitchView { mode in
                // Block mode-switch mid-call — tearing down the expert
                // socket + role context would kill the active session.
                guard CallCenter.shared.attempt("switch modes") else { return }
                // Flip the app's active home mode. ClickMe2026App
                // observes `currentMode` and snaps to the corresponding
                // home route immediately.
                UserManager.shared.setMode(mode)
            }
        }
    }

    /// Push destination for "View My Public Profile" — reuses the
    /// client-side `ExpertProfileView` in self-view mode.
    ///
    /// Expert id source cascades: `me.id` (refreshed on cold launch)
    /// → `authUser.id` (only set during same-session login/signup).
    /// Everything else (name, avatar) comes from the same VM that
    /// already renders the user card above, so a hard fallback to
    /// the placeholder is only reached if the auth state is genuinely
    /// unusable — which shouldn't happen for a logged-in expert.
    @ViewBuilder
    private var myPublicProfileDestination: some View {
        let expertId = UserManager.shared.me?.id
            ?? UserManager.shared.authUser?.id
        let displayName = viewModel.name.isEmpty
            ? UserManager.shared.authUser.map {
                "\($0.firstName) \($0.lastName)".trimmingCharacters(in: .whitespaces)
              } ?? ""
            : viewModel.name
        let avatarURL = viewModel.avatarURL.isEmpty
            ? (UserManager.shared.authUser?.avatarUrl ?? "")
            : viewModel.avatarURL

        if let expertId {
            ExpertProfileView(
                expert: PublicExpertProfile(
                    expertId: expertId,
                    name: displayName,
                    title: "",
                    rating: 0,
                    reviewCount: 0,
                    yearsExp: "",
                    bookings: "",
                    isOnline: viewModel.isOnline,
                    bio: "",
                    expertiseTags: [],
                    topics: [],
                    reviews: [],
                    imageURL: avatarURL
                ),
                isSelfView: true
            )
        } else {
            placeholder(title: "My Profile")
        }
    }

    private func placeholder(title: String) -> some View {
        ZStack {
            ClientProfileHomeBrand.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "hammer.fill")
                    .font(.title.weight(.light))
                    .foregroundColor(ClientProfileHomeBrand.onSurfaceVar)
                Text("\(title) — coming soon")
                    .font(.brand(.subheadline))
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
                .font(.caption.weight(.medium))
                .foregroundColor(ClientProfileHomeBrand.onSurfaceVar)
            Text("© 2026 ClickMe Innovations")
                .font(.caption.weight(.medium))
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
