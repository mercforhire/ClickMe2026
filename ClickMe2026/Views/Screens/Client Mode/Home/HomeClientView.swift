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
        // `BookingRequestSentView`. Both unwind the source tab (Explore
        // — where MakeABookingView was pushed from) so the user
        // doesn't find the booking flow still on the stack when they
        // navigate back there later.
        .environment(\.showMyBookings, HomeShellAction {
            explorePath.reset()
            bookingsPath.reset()
            selectedTab = .bookings
        })
        .environment(\.returnToHome, HomeShellAction {
            explorePath.reset()
            selectedTab = .explore
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
        .onChange(of: pushRouter.pendingDestination) { _, destination in
            handlePushDestination(destination)
        }
        .onAppear {
            handlePushDestination(pushRouter.pendingDestination)
        }
    }

    /// Route a tapped push notification to the appropriate tab + view.
    private func handlePushDestination(_ destination: PushDestination?) {
        guard let destination else { return }
        switch destination {
        case let .bookingDetail(bookingId):
            selectedTab = .bookings
            bookingsPath.push(HomeRoute.upcomingBooking(bookingId: bookingId))
        case .incomingRequests:
            // Expert-only push. If a client shell somehow receives it,
            // fall back to the notifications list rather than stranding
            // the user on a blank landing.
            explorePath.push(HomeRoute.notifications)
        case let .chatThread(threadId):
            selectedTab = .chats
            chatsPath.push(HomeRoute.chat(
                threadId: threadId,
                peerName: "",
                peerAvatarURL: ""
            ))
        case let .leaveReview(bookingId):
            // Land on the past-summary — its Leave Review CTA takes
            // the client the rest of the way.
            selectedTab = .bookings
            bookingsPath.push(HomeRoute.bookingSummary(bookingId: bookingId))
        case .payouts, .kycOnboarding:
            // Client shell has no payout surface — payouts belong to
            // expert mode. Fall back to the notifications list so the
            // user isn't stranded on a blank landing.
            explorePath.push(HomeRoute.notifications)
        case .accountSecurity:
            selectedTab = .profile
            profilePath.push(HomeRoute.accountSecurity)
        case .notificationsList:
            explorePath.push(HomeRoute.notifications)
        }
        pushRouter.pendingDestination = nil
    }

    // MARK: - Tabs

    /// Explore tab. Owns the branded top bar (only tab that shows it).
    /// Registers `HomeRoute` destinations so the bell + avatar buttons
    /// push notifications / mode-switch onto Explore's stack.
    private var exploreTab: some View {
        NavigationStack(path: $explorePath.path) {
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
            .navigationDestination(for: HomeRoute.self) { route in
                homeRouteDestination(route)
            }
        }
        .environment(\.homeNavigationPath, explorePath)
    }

    private var searchTab: some View {
        NavigationStack(path: $searchPath.path) {
            SearchExpertView()
        }
        .environment(\.homeNavigationPath, searchPath)
    }

    private var bookingsTab: some View {
        NavigationStack(path: $bookingsPath.path) {
            MyBookingsView()
        }
        .environment(\.homeNavigationPath, bookingsPath)
    }

    /// Chats tab. Registers `HomeRoute` destinations so the `openChatThread`
    /// shell action can push `.chat(...)` onto this tab's stack when
    /// invoked from any other tab.
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
            ClientProfileHomeScreen()
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
        case .expertPayouts:
            // Expert-only surface. Unreachable from the client shell.
            EmptyView()
        case .accountSecurity:
            AccountSecurityView()
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
