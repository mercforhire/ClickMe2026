//
//  HomeClientView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Client home tab shell

struct HomeClientView: View {
    @State private var selectedTab: HomeClientTab = .explore
    @State private var showOnboarding: Bool = false

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeClientTopBar()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HomeClientTabBar(selection: $selectedTab)
        }
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

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .explore:
            ExploreClientView()
        case .search:
            SearchExpertView()
        case .bookings:
            MyBookingsView()
        case .chats:
            ChatConversationsView()
        case .profile:
            ClientProfileHomeScreen()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeClientView()
        .preferredColorScheme(.dark)
}
