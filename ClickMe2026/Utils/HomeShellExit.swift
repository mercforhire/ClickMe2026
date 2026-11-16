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
///
/// Both shells use the plan, generic over their tab enum. The client shell
/// installs all three exits. The expert shell installs `viewMyBookings`, for
/// Delete Account's blocker alert (D-10), and `backToHomeRoot`, for Booking
/// Confirmed's Back to Home (D-11), so it never asks for the Past segment.
struct HomeShellExit<Tab: HomeShellTab>: Equatable {

    /// The shell actions that leave the booking flow.
    enum Action: Equatable {
        case backToHome
        /// Resets the source tab and the home tab, then shows the home tab.
        /// Used by the expert Booking Confirmed screen (D-11); unlike
        /// `backToHome`, the home tab's own stack is emptied too.
        case backToHomeRoot
        case viewMyBookings
        case viewMyHistory
    }

    /// Tabs whose stacks are emptied.
    let resetTabs: Set<Tab>

    /// Tab selected after the reset.
    let showTab: Tab

    /// Whether the Bookings tab opens on its Past segment. Only
    /// `viewMyHistory` sets it.
    let showsPastBookings: Bool

    /// The exit for `action`, started from `selectedTab`.
    ///
    /// - Parameters:
    ///   - action: The exit the user tapped.
    ///   - selectedTab: The tab selected at tap time, the source of the flow.
    static func plan(_ action: Action, selectedTab: Tab) -> HomeShellExit {
        switch action {
        case .backToHome:
            return HomeShellExit(
                resetTabs: [selectedTab],
                showTab: Tab.homeTab,
                showsPastBookings: false
            )
        case .backToHomeRoot:
            return HomeShellExit(
                resetTabs: [selectedTab, Tab.homeTab],
                showTab: Tab.homeTab,
                showsPastBookings: false
            )
        case .viewMyBookings:
            return HomeShellExit(
                resetTabs: [selectedTab, Tab.bookingsTab],
                showTab: Tab.bookingsTab,
                showsPastBookings: false
            )
        case .viewMyHistory:
            return HomeShellExit(
                resetTabs: [selectedTab, Tab.bookingsTab],
                showTab: Tab.bookingsTab,
                showsPastBookings: true
            )
        }
    }
}

// MARK: - Shell tab conformances

/// What a shell's tab enum supplies to the shared exit plan: the tab a
/// "back to home" exit shows and the tab that lists the user's bookings.
protocol HomeShellTab: Hashable {
    /// The shell's landing tab.
    static var homeTab: Self { get }

    /// The shell's Bookings tab.
    static var bookingsTab: Self { get }
}

extension HomeClientTab: HomeShellTab {
    static var homeTab: HomeClientTab { .explore }
    static var bookingsTab: HomeClientTab { .bookings }
}

extension HomeExpertTab: HomeShellTab {
    static var homeTab: HomeExpertTab { .dashboard }
    static var bookingsTab: HomeExpertTab { .bookings }
}
