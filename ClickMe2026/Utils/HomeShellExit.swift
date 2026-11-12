//
//  HomeShellExit.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

// MARK: - Shell exit planner

/// Which tab stacks to reset, and which tab to show, when a screen leaves the
/// booking flow through a shell action (BOOK-19, D-06).
///
/// Each tab owns its own navigation stack (Phase 2 D-04), so a booking started
/// from Search, Chats or Profile lives on that tab's stack, not Explore's. The
/// source tab is the tab selected when the exit is tapped: the exit buttons
/// exist only on the visible tab, so the selected tab at tap time is the one
/// holding the flow. Resetting only Explore would leave Request Sent stuck on
/// every other tab.
///
/// `resetTabs` is a set, so a tab named twice (Explore as the source of
/// `Back to Home`) is reset once. The plan depends only on its inputs, so a
/// double tap gives the same plan and resetting an already-empty path is a
/// no-op.
///
/// The Favorites empty state's two buttons use the same planner (D-08).
/// "Explore Experts" is `backToHome` from the Profile tab: it resets Profile
/// and shows Explore without touching Explore's stack. "View My History" is
/// `viewMyHistory`: it resets the source tab and Bookings, shows Bookings and
/// asks for its Past segment.
struct HomeShellExit: Equatable {

    /// The shell actions that leave the booking flow.
    enum Action: Equatable {
        case backToHome
        case viewMyBookings
        case viewMyHistory
    }

    /// Tabs whose stacks are emptied.
    let resetTabs: Set<HomeClientTab>

    /// Tab selected after the reset.
    let showTab: HomeClientTab

    /// Whether the Bookings tab opens on its Past segment. Only
    /// `viewMyHistory` sets it.
    let showsPastBookings: Bool

    /// The exit for `action`, started from `selectedTab`.
    ///
    /// - Parameters:
    ///   - action: The exit the user tapped.
    ///   - selectedTab: The tab selected at tap time, the source of the flow.
    static func plan(_ action: Action, selectedTab: HomeClientTab) -> HomeShellExit {
        switch action {
        case .backToHome:
            return HomeShellExit(
                resetTabs: [selectedTab],
                showTab: .explore,
                showsPastBookings: false
            )
        case .viewMyBookings:
            return HomeShellExit(
                resetTabs: [selectedTab, .bookings],
                showTab: .bookings,
                showsPastBookings: false
            )
        case .viewMyHistory:
            return HomeShellExit(
                resetTabs: [selectedTab, .bookings],
                showTab: .bookings,
                showsPastBookings: true
            )
        }
    }
}
