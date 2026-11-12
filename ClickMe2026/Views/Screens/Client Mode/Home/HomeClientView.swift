//
//  HomeClientView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Client home tab shell

/// The client-mode tab shell. Uses SwiftUI's native `TabView` so each
/// tab owns its own `NavigationStack` and preserves nav state across
/// tab switches — a user who taps Message from an expert profile lands
/// on the Chats tab with the thread pushed, and switching back to
/// Explore keeps the expert profile visible where they left it.
struct HomeClientView: View {
    @State private var selectedTab: HomeClientTab = .explore
    @State private var showOnboarding: Bool = false

    /// Read so the top-bar avatar refreshes reactively when the
    /// user updates their photo (or when `UserManager.refreshProfile`
    /// completes on cold launch). `@Observable` tracks reads on this
    /// singleton automatically — no property wrapper required.
    private let userManager = UserManager.shared
    /// Observed so a tapped push notification lands on the right tab.
    @ObservedObject private var pushRouter = PushRouter.shared
    /// A tap held for unknown roles is planned again when the app returns
    /// to the foreground (for example after airplane mode is turned off).
    @Environment(\.scenePhase) private var scenePhase

    // MARK: Per-tab nav paths
    //
    // One `HomeNavigationPath` per tab, kept alive for the shell's
    // lifetime as `@StateObject` so each tab preserves its nav trail
    // when the user tab-switches away and back. Leaf views inside each
    // tab read from `@Environment(\.homeNavigationPath)` (installed per
    // tab below) to push destinations.
    @StateObject private var explorePath = HomeNavigationPath()
    @StateObject private var searchPath = HomeNavigationPath()
    @StateObject private var bookingsPath = HomeNavigationPath()
    @StateObject private var chatsPath = HomeNavigationPath()
    @StateObject private var profilePath = HomeNavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            exploreTab
                .tabItem { Label("Explore", systemImage: "sparkles") }
                .tag(HomeClientTab.explore)

            searchTab
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(HomeClientTab.search)

            bookingsTab
                .tabItem { Label("Bookings", systemImage: "calendar") }
                .tag(HomeClientTab.bookings)

            chatsTab
                .tabItem { Label("Chats", systemImage: "message") }
                .tag(HomeClientTab.chats)

            profileTab
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(HomeClientTab.profile)
        }
        .tint(Brand.primary)
        // Lock the shell into dark mode so system chrome (nav bar +
        // tab bar) doesn't flash to a light appearance during tab
        // transitions when a destination view hasn't explicitly set
        // its own toolbar background.
        .preferredColorScheme(.dark)
        // Chat-open action lives at the shell level so any tab's leaf
        // views can invoke it — switches to the Chats tab AND pushes
        // the thread onto the Chats tab's own path.
        .environment(\.openChatThread, OpenChatThreadAction { threadId, peerName, peerAvatarURL in
            selectedTab = .chats
            chatsPath.push(HomeRoute.chat(
                threadId: threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            ))
        })
        // Post-booking navigation shortcuts consumed by
        // `BookingRequestSentView`. Both unwind the source tab (the tab
        // selected at tap time, where MakeABookingView was pushed from:
        // Explore, Search, Bookings, Chats or Profile) so the user
        // doesn't find the booking flow still on the stack when they
        // navigate back there later (BOOK-19, D-06).
        .environment(\.showMyBookings, HomeShellAction {
            applyExit(HomeShellExit.plan(.viewMyBookings, selectedTab: selectedTab))
        })
        .environment(\.returnToHome, HomeShellAction {
            applyExit(HomeShellExit.plan(.backToHome, selectedTab: selectedTab))
        })
        // Global call surface + floating pill overlays. Sits above the
        // TabView but below any modal (sheet / fullScreenCover), so
        // ordinary navigation continues to work while a call is in
        // progress — the user just sees the pill / expanded call
        // hovering above the tabs.
        .modifier(CallOverlayHost { threadId, peerName, peerAvatarURL in
            selectedTab = .chats
            chatsPath.push(HomeRoute.chat(
                threadId: threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            ))
        })
        // Shared transient confirmation ("Reschedule accepted", ...). Owned
        // here, above the tab stacks, so a message posted just before a pop
        // still shows after it. The expert shell hosts one too.
        .modifier(ToastHost())
        .task {
            // Show the onboarding modal exactly once per login. `logout()`
            // clears the flag so the next sign-in re-shows it.
            if !UserManager.shared.hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(
                onNext: {
                    UserManager.shared.markOnboardingShown()
                    showOnboarding = false
                },
                onSkip: {
                    UserManager.shared.markOnboardingShown()
                    showOnboarding = false
                }
            )
        }
        // Consume the queued push tap. Fires when a tap arrives while this
        // shell is up, when the shell mounts with a tap already queued (cold
        // launch, or a mode switch made for that tap), when the account's
        // roles load, and when the app returns to the foreground, so a tap
        // held for unknown roles is planned as soon as they are known.
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
    }

    /// Plan the queued tap for client mode (D-02, D-03). A nil plan means
    /// nothing is queued, a newer tap superseded it, or it is waiting for
    /// the account's roles. A mode switch hands the tap to the expert shell,
    /// which mounts and consumes it (so it is not cleared here); otherwise
    /// the destination opens and the queue is cleared. Running the same plan
    /// twice is harmless, so overlapping triggers need no guard.
    private func consumePendingPush() {
        Task {
            guard let plan = await pushRouter.planPending(currentMode: .client) else { return }
            if let mode = plan.switchToMode {
                userManager.setMode(mode)
                return
            }
            handlePushDestination(plan.destination)
            pushRouter.pending = nil
        }
    }

    /// Open a push or notifications-list destination on the tab that owns
    /// it (D-04): select the tab, replace its stack with the destination in
    /// one mutation, so Back returns to the tab's root. Ownership: booking
    /// detail and leave-review on Bookings, chat on Chats, account security
    /// on Profile, and the notifications list on Explore. Expert-only
    /// destinations also land on Explore's notifications list, because the
    /// client shell has no screen for them.
    private func handlePushDestination(_ destination: PushDestination) {
        switch destination {
        case let .bookingDetail(bookingId):
            selectedTab = .bookings
            bookingsPath.replace(with: HomeRoute.upcomingBooking(bookingId: bookingId))
        case let .bookingSummary(bookingId):
            // A declined, cancelled, expired or refunded booking — the
            // read-only summary, not the upcoming-booking screen.
            selectedTab = .bookings
            bookingsPath.replace(with: HomeRoute.bookingSummary(bookingId: bookingId))
        case .incomingRequests, .incomingRequest:
            // Expert-only push. If a client shell somehow receives it,
            // fall back to the notifications list rather than stranding
            // the user on a blank landing.
            selectedTab = .explore
            explorePath.replace(with: HomeRoute.notifications)
        case let .chatThread(threadId):
            selectedTab = .chats
            chatsPath.replace(with: HomeRoute.chat(
                threadId: threadId,
                peerName: "",
                peerAvatarURL: ""
            ))
        case let .leaveReview(bookingId):
            // Land on the past-summary — its Leave Review CTA takes
            // the client the rest of the way.
            selectedTab = .bookings
            bookingsPath.replace(with: HomeRoute.bookingSummary(bookingId: bookingId))
        case .payouts, .kycOnboarding:
            // Client shell has no payout surface — payouts belong to
            // expert mode. Fall back to the notifications list so the
            // user isn't stranded on a blank landing.
            selectedTab = .explore
            explorePath.replace(with: HomeRoute.notifications)
        case .accountSecurity:
            selectedTab = .profile
            profilePath.replace(with: HomeRoute.accountSecurity)
        case .notificationsList:
            selectedTab = .explore
            explorePath.replace(with: HomeRoute.notifications)
        }
    }

    // MARK: - Booking-flow exits

    /// Apply a planned exit: empty every stack in `resetTabs`, then show
    /// `showTab`. `HomeNavigationPath.reset()` is a no-op on an empty path, so
    /// a repeated exit changes nothing (BOOK-19, D-06).
    private func applyExit(_ exit: HomeShellExit) {
        for tab in exit.resetTabs {
            path(for: tab).reset()
        }
        selectedTab = exit.showTab
    }

    private func path(for tab: HomeClientTab) -> HomeNavigationPath {
        switch tab {
        case .explore: return explorePath
        case .search: return searchPath
        case .bookings: return bookingsPath
        case .chats: return chatsPath
        case .profile: return profilePath
        }
    }

    // MARK: - Tabs

    /// `homeStack(_:path:root:)` builds one `NavigationStack` per tab, with
    /// `HomeRoute` registered exactly once. Every tab goes through it so no
    /// routed destination can land on a stack that does not know it (CR-01).
    /// Destinations receive the originating tab's path, so a flow that pops
    /// itself (cancel, reschedule) pops the tab that pushed it.
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
    }

    /// Explore tab. Owns the branded top bar (only tab that shows it);
    /// the bell + avatar buttons push notifications / mode-switch onto
    /// Explore's stack.
    private var exploreTab: some View {
        homeStack(explorePath, path: $explorePath.path) {
            ExploreClientView(
                onSeeAllExperts: { selectedTab = .search }
            )
            .safeAreaInset(edge: .top, spacing: 0) {
                HomeClientTopBar(
                    avatarURL: userManager.profile?.personalDetails.avatarUrl,
                    onNotifications: { explorePath.push(HomeRoute.notifications) },
                    onProfile: { explorePath.push(HomeRoute.modeSwitch) }
                )
            }
        }
    }

    private var searchTab: some View {
        homeStack(searchPath, path: $searchPath.path) {
            SearchExpertView()
        }
    }

    /// Bookings tab. `MyBookingsView` registers its own `BookingRoute`
    /// destinations; `HomeRoute` comes from `homeStack` so a push tap can
    /// open a booking here.
    private var bookingsTab: some View {
        homeStack(bookingsPath, path: $bookingsPath.path) {
            MyBookingsView()
        }
    }

    /// Chats tab. The `openChatThread` shell action pushes `.chat(...)`
    /// onto this tab's stack when invoked from any other tab.
    private var chatsTab: some View {
        homeStack(chatsPath, path: $chatsPath.path) {
            ChatConversationsView()
        }
    }

    private var profileTab: some View {
        homeStack(profilePath, path: $profilePath.path) {
            ClientProfileHomeScreen()
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
        case .expertBookingSummary:
            // Expert-only destination. Not reachable from the client shell,
            // but the case must be exhaustive.
            EmptyView()
        case .expertReschedule:
            // Expert-only destination. Not reachable from the client shell.
            EmptyView()
        case .incomingRequests:
            // Expert-only. If a client somehow lands here (deep-link
            // with wrong mode), do nothing.
            EmptyView()
        case .requestDecision:
            // Expert-only. Unreachable from the client shell.
            EmptyView()
        case .expertPayouts:
            // Expert-only surface. Unreachable from the client shell.
            EmptyView()
        case .accountSecurity:
            AccountSecurityView()
        case let .cancelBooking(bookingId):
            // Keep Booking goes back one level, to Upcoming details (BOOK-12).
            // A confirmed cancel pops two: this screen and the details of the
            // booking it just cancelled, landing on whatever opened them. The
            // cancel toast is posted by the view model before this runs.
            ClientCancellationView(
                bookingId: bookingId,
                onKeepBooking: { nav.pop() },
                onConfirmCancellation: { _, _ in nav.pop(2) }
            )
        case let .rescheduleBooking(bookingId):
            // A sent request pops one level, back to Upcoming details; the
            // "Reschedule request sent" toast is posted by the view model
            // (D-11, BOOK-16).
            RescheduleView(
                bookingId: bookingId,
                onRescheduled: { nav.pop() }
            )
        case let .writeReview(bookingId, expertName):
            // Only offered for completed sessions (BOOK-17), so the status is fixed.
            WriteReviewView(
                bookingId: bookingId,
                bookingStatus: .completed,
                seedExpertName: expertName
            )
        case let .peerProfile(userId, name, avatarURL):
            // Client is viewing the expert they were chatting with —
            // seed the profile with what we already know, then let the
            // view fetch bio/topics/reviews via /experts/:id/details.
            ExpertProfileView(
                expert: PublicExpertProfile(
                    expertId: userId,
                    name: name,
                    title: "",
                    rating: 0,
                    reviewCount: 0,
                    yearsExp: "",
                    bookings: "",
                    isOnline: false,
                    bio: "",
                    expertiseTags: [],
                    topics: [],
                    reviews: [],
                    imageURL: avatarURL
                )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    HomeClientView()
        .preferredColorScheme(.dark)
}
