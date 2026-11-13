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
    /// A tap held for unknown roles is planned again when the app returns
    /// to the foreground (for example after airplane mode is turned off).
    @Environment(\.scenePhase) private var scenePhase
    /// Observed so a tap held during a call is replayed when the call ends
    /// (the `CallOverlayHost` pattern).
    @ObservedObject private var callCenter = CallCenter.shared

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
        // Delete Account's blocker alert (plan 05-08) offers "View my bookings"
        // when this is set. Same plan the client shell uses: reset the tab
        // the flow started on and Bookings, then show Bookings (D-10).
        .environment(\.showMyBookings, HomeShellAction {
            applyExit(HomeShellExit.plan(.viewMyBookings, selectedTab: selectedTab))
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
        // Shared transient confirmation. A dual-role user can open a client
        // booking from a chat row here and answer a reschedule proposal, so
        // "Reschedule accepted" / "Reschedule declined" need a host in this
        // shell too, or they surface later in client mode (WR-05).
        .modifier(ToastHost())
        // Consume the queued push tap. Fires when a tap arrives while this
        // shell is up, when the shell mounts with a tap already queued (cold
        // launch, or a mode switch made for that tap), when the account's
        // roles load, and when the app returns to the foreground, so a tap
        // held for unknown roles is planned as soon as they are known. A tap
        // held during a call opens when the call ends.
        .onChange(of: pushRouter.pending) { _, _ in
            consumePendingPush()
        }
        .onAppear {
            consumePendingPush()
        }
        .onChange(of: userManager.me?.roles) { _, _ in
            consumePendingPush()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { consumePendingPush() }
        }
        // A tap held because a call blocked its mode switch opens now.
        // Ending a call shows no post-call screen in the shell, so the
        // switch tears nothing down.
        .onChange(of: callCenter.isCallActive) { _, active in
            if !active { consumePendingPush() }
        }
    }

    /// Plan the queued tap for expert mode (D-02). A nil plan means nothing
    /// is queued or a newer tap superseded it. A client-targeted tap switches
    /// to client mode and hands the tap to the client shell, which mounts
    /// and consumes it (so it is not cleared here); otherwise the destination
    /// opens and the queue is cleared, so a subsequent identical push still
    /// fires (SwiftUI's `onChange` skips duplicate values). Running the same
    /// plan twice is harmless, so overlapping triggers need no guard.
    private func consumePendingPush() {
        Task {
            guard let plan = await pushRouter.planPending(currentMode: .expert) else { return }
            if let mode = plan.switchToMode {
                // A push never opens the setup hub and never raises the
                // "switch modes" call alert: a replay on every foreground
                // would nag. The gate itself refuses the switch during a call.
                switch await userManager.requestModeSwitch(mode, source: .push) {
                case .switched:
                    // The other shell mounts and consumes the tap.
                    return
                case .setupRequired:
                    // Setup is unfinished: plan the tap again. The gate fetched
                    // the incomplete profile, so the planner now opens the
                    // notifications list instead of asking for a switch.
                    consumePendingPush()
                    return
                case .blockedByCall:
                    // A call is active, so the switch waits (single-call
                    // invariant). The tap stays queued until the call ends and
                    // the call-end observer replays it.
                    return
                case .sessionEnded, .superseded:
                    return
                }
            }
            handlePushDestination(plan.destination)
            pushRouter.pending = nil
        }
    }

    /// Open a push or notifications-list destination on the tab that owns
    /// it (D-04): select the tab, replace its stack with the destination in
    /// one mutation, so Back returns to the tab's root. Ownership: booking
    /// detail and leave-review on Bookings, the request hub, payouts and the
    /// notifications list on Dashboard, chat on Chats, account security on
    /// Profile.
    private func handlePushDestination(_ destination: PushDestination) {
        switch destination {
        case let .bookingDetail(bookingId):
            selectedTab = .bookings
            bookingsPath.replace(with: HomeRoute.expertBookingSummary(bookingId: bookingId))
        case let .bookingSummary(bookingId):
            // A declined, cancelled, expired or refunded booking.
            selectedTab = .bookings
            bookingsPath.replace(with: HomeRoute.expertBookingSummary(bookingId: bookingId))
        case let .incomingRequest(bookingId):
            // The request id is the bookings row id, so the push's booking
            // id opens that request's decision screen directly.
            selectedTab = .dashboard
            dashboardPath.replace(with: HomeRoute.requestDecision(requestId: bookingId))
        case .incomingRequests:
            // Booking-request notifications land here — the pending
            // requests hub, reachable from the dashboard tab.
            selectedTab = .dashboard
            dashboardPath.replace(with: HomeRoute.incomingRequests)
        case let .chatThread(threadId):
            selectedTab = .chats
            chatsPath.replace(with: HomeRoute.chat(
                threadId: threadId,
                peerName: "",
                peerAvatarURL: ""
            ))
        case let .leaveReview(bookingId):
            // Experts don't leave reviews — land on the summary and
            // let them read the completed session.
            selectedTab = .bookings
            bookingsPath.replace(with: HomeRoute.expertBookingSummary(bookingId: bookingId))
        case .payouts, .kycOnboarding:
            // Both go to `PayoutsView` — the KYC onboarding banner
            // lives on that screen when Stripe Connect isn't fully
            // set up, so a `payout/kyc_action` push lands one tap
            // away from the onboarding CTA.
            selectedTab = .dashboard
            dashboardPath.replace(with: HomeRoute.expertPayouts)
        case .accountSecurity:
            selectedTab = .profile
            profilePath.replace(with: HomeRoute.accountSecurity)
        case .notificationsList:
            selectedTab = .dashboard
            dashboardPath.replace(with: HomeRoute.notifications)
        }
    }

    // MARK: - Shell exits

    /// Apply a planned exit: empty every stack in `resetTabs`, then show
    /// `showTab`. `HomeNavigationPath.reset()` is a no-op on an empty path, so
    /// a repeated exit changes nothing. `showsPastBookings` is never set by
    /// the one exit this shell installs, so it is not read here.
    private func applyExit(_ exit: HomeShellExit<HomeExpertTab>) {
        for tab in exit.resetTabs {
            path(for: tab).reset()
        }
        selectedTab = exit.showTab
    }

    private func path(for tab: HomeExpertTab) -> HomeNavigationPath {
        switch tab {
        case .dashboard: return dashboardPath
        case .bookings: return bookingsPath
        case .topics: return topicsPath
        case .chats: return chatsPath
        case .profile: return profilePath
        }
    }

    // MARK: - Tabs

    /// `homeStack(_:path:root:)` builds one `NavigationStack` per tab, with
    /// `HomeRoute` registered exactly once. Every tab goes through it so no
    /// routed destination can land on a stack that does not know it (CR-01).
    /// Destinations receive the originating tab's path, so a route that pops
    /// itself (the reschedule form) pops the tab that pushed it (EXP-13).
    private func homeStack<Root: View>(
        _ nav: HomeNavigationPath,
        path: Binding<NavigationPath>,
        @ViewBuilder root: () -> Root
    ) -> some View {
        NavigationStack(path: path) {
            root()
                .navigationDestination(for: HomeRoute.self) { route in
                    homeRouteDestination(route, nav: nav)
                }
        }
        .environment(\.homeNavigationPath, nav)
        // Pairs with the three client-only stubs below: the client Upcoming
        // details and Booking Summary are reachable here from chat rows, and
        // must not offer actions that would push a stubbed route.
        .environment(\.hostsClientBookingFlows, false)
    }

    private var dashboardTab: some View {
        homeStack(dashboardPath, path: $dashboardPath.path) {
            ExpertDashboardView()
                .safeAreaInset(edge: .top, spacing: 0) {
                    HomeExpertTopBar(
                        avatarURL: userManager.profile?.personalDetails.avatarUrl,
                        onNotifications: { dashboardPath.push(HomeRoute.notifications) },
                        onProfile: { dashboardPath.push(HomeRoute.modeSwitch) }
                    )
                }
        }
    }

    private var bookingsTab: some View {
        homeStack(bookingsPath, path: $bookingsPath.path) {
            UpcomingBookingsView()
        }
    }

    private var topicsTab: some View {
        homeStack(topicsPath, path: $topicsPath.path) {
            TopicsSetupView()
        }
    }

    private var chatsTab: some View {
        homeStack(chatsPath, path: $chatsPath.path) {
            ChatConversationsView()
        }
    }

    private var profileTab: some View {
        homeStack(profilePath, path: $profilePath.path) {
            ExpertProfileHomeScreen()
        }
    }

    // MARK: - Shared HomeRoute destination

    @ViewBuilder
    private func homeRouteDestination(_ route: HomeRoute, nav: HomeNavigationPath) -> some View {
        switch route {
        case .notifications:
            NotificationsListView()
        case .modeSwitch:
            ModeSwitchView { mode in
                // Same gate as Profile > Mode Switch (D-03): adds the
                // "End the call to switch modes." guard this route lacked.
                Task { await ModeSwitchGate.request(mode) }
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
                nav.pop()
            })
        case let .peerProfile(userId, _, _):
            // Expert is viewing their client — ClientProfileView loads
            // everything by id, so name/avatar seeds are unused here.
            ClientProfileView(clientId: userId)
        case .incomingRequests:
            IncomingRequestsView()
        case let .requestDecision(requestId):
            RequestDecisionView(requestId: requestId)
        case .expertPayouts:
            PayoutsView()
        case .accountSecurity:
            AccountSecurityView()
        case .cancelBooking:
            // Client-only destination. Not reachable from the expert shell
            // (hostsClientBookingFlows is false), but the case must be exhaustive.
            EmptyView()
        case .rescheduleBooking:
            // Client-only destination. Not reachable from the expert shell.
            EmptyView()
        case .writeReview:
            // Client-only destination. Not reachable from the expert shell.
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeExpertView()
        .preferredColorScheme(.dark)
}
