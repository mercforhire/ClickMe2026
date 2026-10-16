//
//  HomeExpertView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Expert home tab shell

/// The expert-mode tab shell. Uses SwiftUI's native `TabView` so each
/// tab owns its own `NavigationStack` and preserves nav state across
/// tab switches.
struct HomeExpertView: View {
    @State private var selectedTab: HomeExpertTab = .dashboard

    /// Read so the top-bar avatar refreshes reactively. `@Observable`
    /// tracks reads on this singleton automatically — no property
    /// wrapper required.
    private let userManager = UserManager.shared
    /// Observed so a tapped push notification lands on the right tab.
    @ObservedObject private var pushRouter = PushRouter.shared

    // MARK: Per-tab nav paths — persistent across tab switches.
    @StateObject private var dashboardPath = HomeNavigationPath()
    @StateObject private var bookingsPath = HomeNavigationPath()
    @StateObject private var topicsPath = HomeNavigationPath()
    @StateObject private var chatsPath = HomeNavigationPath()
    @StateObject private var profilePath = HomeNavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            dashboardTab
                .tabItem { Label("Dashboard", systemImage: "house") }
                .tag(HomeExpertTab.dashboard)

            bookingsTab
                .tabItem { Label("Bookings", systemImage: "calendar") }
                .tag(HomeExpertTab.bookings)

            topicsTab
                .tabItem { Label("Topics", systemImage: "pencil.and.list.clipboard") }
                .tag(HomeExpertTab.topics)

            chatsTab
                .tabItem { Label("Chats", systemImage: "message") }
                .tag(HomeExpertTab.chats)

            profileTab
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(HomeExpertTab.profile)
        }
        .tint(Brand.primary)
        // Lock the shell into dark mode so system chrome (nav bar +
        // tab bar) doesn't flash to a light appearance during tab
        // transitions when a destination view hasn't explicitly set
        // its own toolbar background.
        .preferredColorScheme(.dark)
        .environment(\.openChatThread, OpenChatThreadAction { threadId, peerName, peerAvatarURL in
            selectedTab = .chats
            chatsPath.push(HomeRoute.chat(
                threadId: threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            ))
        })
        // Global call surface + floating pill overlays.
        .modifier(CallOverlayHost { threadId, peerName, peerAvatarURL in
            selectedTab = .chats
            chatsPath.push(HomeRoute.chat(
                threadId: threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            ))
        })
        // Consume any pending deep-link the router parked when a push
        // was tapped. Fires whether the shell was already on-screen
        // or just came up.
        .onChange(of: pushRouter.pendingDestination) { _, destination in
            handlePushDestination(destination)
        }
        .onAppear {
            // In case the destination was set before this view mounted
            // (e.g. app cold-started via a notification tap), consume
            // it now.
            handlePushDestination(pushRouter.pendingDestination)
        }
    }

    /// Route a tapped push notification to the appropriate tab + view.
    /// Clears `pendingDestination` after handling so a subsequent
    /// identical push still fires (SwiftUI's `onChange` skips
    /// duplicate values).
    private func handlePushDestination(_ destination: PushDestination?) {
        guard let destination else { return }
        switch destination {
        case let .bookingDetail(bookingId):
            selectedTab = .bookings
            bookingsPath.push(HomeRoute.expertBookingSummary(bookingId: bookingId))
        case .incomingRequests:
            // Booking-request notifications land here — the pending
            // requests hub, reachable from the dashboard tab.
            selectedTab = .dashboard
            dashboardPath.push(HomeRoute.incomingRequests)
        case let .chatThread(threadId):
            selectedTab = .chats
            chatsPath.push(HomeRoute.chat(
                threadId: threadId,
                peerName: "",
                peerAvatarURL: ""
            ))
        case let .leaveReview(bookingId):
            // Experts don't leave reviews — land on the summary and
            // let them read the completed session.
            selectedTab = .bookings
            bookingsPath.push(HomeRoute.expertBookingSummary(bookingId: bookingId))
        case .payouts, .kycOnboarding:
            // Both go to `PayoutsView` — the KYC onboarding banner
            // lives on that screen when Stripe Connect isn't fully
            // set up, so a `payout/kyc_action` push lands one tap
            // away from the onboarding CTA.
            selectedTab = .dashboard
            dashboardPath.push(HomeRoute.expertPayouts)
        case .accountSecurity:
            selectedTab = .profile
            profilePath.push(HomeRoute.accountSecurity)
        case .notificationsList:
            dashboardPath.push(HomeRoute.notifications)
        }
        pushRouter.pendingDestination = nil
    }

    // MARK: - Tabs

    private var dashboardTab: some View {
        NavigationStack(path: $dashboardPath.path) {
            ExpertDashboardView()
                .safeAreaInset(edge: .top, spacing: 0) {
                    HomeExpertTopBar(
                        avatarURL: userManager.profile?.personalDetails.avatarUrl,
                        onNotifications: { dashboardPath.push(HomeRoute.notifications) },
                        onProfile: { dashboardPath.push(HomeRoute.modeSwitch) }
                    )
                }
                .navigationDestination(for: HomeRoute.self) { route in
                    homeRouteDestination(route)
                }
        }
        .environment(\.homeNavigationPath, dashboardPath)
    }

    private var bookingsTab: some View {
        NavigationStack(path: $bookingsPath.path) {
            UpcomingBookingsView()
                .navigationDestination(for: HomeRoute.self) { route in
                    homeRouteDestination(route)
                }
        }
        .environment(\.homeNavigationPath, bookingsPath)
    }

    private var topicsTab: some View {
        NavigationStack(path: $topicsPath.path) {
            TopicsSetupView()
        }
        .environment(\.homeNavigationPath, topicsPath)
    }

    private var chatsTab: some View {
        NavigationStack(path: $chatsPath.path) {
            ChatConversationsView()
                .navigationDestination(for: HomeRoute.self) { route in
                    homeRouteDestination(route)
                }
        }
        .environment(\.homeNavigationPath, chatsPath)
    }

    private var profileTab: some View {
        NavigationStack(path: $profilePath.path) {
            ExpertProfileHomeScreen()
                .navigationDestination(for: HomeRoute.self) { route in
                    homeRouteDestination(route)
                }
        }
        .environment(\.homeNavigationPath, profilePath)
    }

    // MARK: - Shared HomeRoute destination

    @ViewBuilder
    private func homeRouteDestination(_ route: HomeRoute) -> some View {
        switch route {
        case .notifications:
            NotificationsListView()
        case .modeSwitch:
            ModeSwitchView { mode in
                userManager.setMode(mode)
            }
        case let .chat(threadId, peerName, peerAvatarURL):
            ChatView(
                threadId: threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            )
        case let .upcomingBooking(bookingId):
            UpcomingBookingView(bookingId: bookingId)
        case let .bookingSummary(bookingId):
            BookingSummaryView(bookingId: bookingId)
        case let .expertBookingSummary(bookingId):
            ExpertBookingSummaryView(bookingId: bookingId)
        case let .expertReschedule(bookingId):
            ExpertRescheduleView(bookingId: bookingId, onRescheduled: {
                bookingsPath.pop()
            })
        case let .peerProfile(userId, _, _):
            // Expert is viewing their client — ClientProfileView loads
            // everything by id, so name/avatar seeds are unused here.
            ClientProfileView(clientId: userId)
        case .incomingRequests:
            IncomingRequestsView()
        case .expertPayouts:
            PayoutsView()
        case .accountSecurity:
            AccountSecurityView()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeExpertView()
        .preferredColorScheme(.dark)
}
