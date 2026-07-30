//
//  HomeExpertView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expert home tab shell

/// The expert-mode tab shell. Uses SwiftUI's native `TabView` so each
/// tab owns its own `NavigationStack` and preserves nav state across
/// tab switches.
struct HomeExpertView: View {
    @State private var selectedTab: HomeExpertTab = .dashboard

    /// Observed so the top-bar avatar refreshes reactively.
    @ObservedObject private var userManager = UserManager.shared

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
        .environment(\.openChatThread, OpenChatThreadAction { threadId, peerName, peerAvatarURL in
            selectedTab = .chats
            chatsPath.push(HomeRoute.chat(
                threadId: threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            ))
        })
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
    HomeExpertView()
        .preferredColorScheme(.dark)
}
