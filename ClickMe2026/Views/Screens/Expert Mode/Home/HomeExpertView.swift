//
//  HomeExpertView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expert home tab shell

struct HomeExpertView: View {
    @State private var selectedTab: HomeExpertTab = .dashboard

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeExpertTopBar()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HomeExpertTabBar(selection: $selectedTab)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .dashboard:
            ExpertDashboardView()
        case .bookings:
            UpcomingBookingsView()
        case .topics:
            TopicsSetupView()
        case .profile:
            ExpertProfileHomeScreen()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeExpertView()
        .preferredColorScheme(.dark)
}
