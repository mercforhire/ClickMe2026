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

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeClientBrand.surface.ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HomeClientTabBar(selection: $selectedTab)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .explore:
            ExploreClientView()
        case .bookings:
            ClickMeMyBookingsView()
        case .chats:
            ClickMeChatsView(chats: [], onSelectChat: { _ in })
        case .profile:
            ClientProfileSettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeClientView()
        .preferredColorScheme(.dark)
}
