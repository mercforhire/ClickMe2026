//
//  HomeClientView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Q42. All rights reserved.
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

    /// Observed so the top-bar avatar refreshes reactively when the
    /// user updates their photo (or when `UserManager.refreshProfile`
    /// completes on cold launch).
    @ObservedObject private var userManager = UserManager.shared

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
        }
    }
}

// MARK: - Preview

#Preview {
    HomeClientView()
        .preferredColorScheme(.dark)
}
