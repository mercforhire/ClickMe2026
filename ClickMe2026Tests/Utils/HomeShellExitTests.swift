//
//  HomeShellExitTests.swift
//  ClickMe2026Tests
//
//  BOOK-19 / D-06: both Request Sent exits reset the tab that started the
//  booking flow, whichever of the five tabs that is.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Home shell exit")
struct HomeShellExitTests {

    @Test("Back to Home resets only the source tab and shows Explore", arguments: HomeClientTab.allCases)
    func backToHome(source: HomeClientTab) {
        let exit = HomeShellExit.plan(.backToHome, selectedTab: source)
        #expect(exit.resetTabs == [source])
        #expect(exit.showTab == .explore)
        #expect(exit.showsPastBookings == false)
    }

    @Test("View My Bookings resets the source tab and Bookings and shows Bookings", arguments: HomeClientTab.allCases)
    func viewMyBookings(source: HomeClientTab) {
        let exit = HomeShellExit.plan(.viewMyBookings, selectedTab: source)
        #expect(exit.resetTabs == [source, .bookings])
        #expect(exit.showTab == .bookings)
        #expect(exit.showsPastBookings == false)
    }

    @Test("View My Bookings from Explore resets Explore and Bookings")
    func viewMyBookingsFromExplore() {
        let exit = HomeShellExit.plan(.viewMyBookings, selectedTab: .explore)
        #expect(exit.resetTabs == [.explore, .bookings])
    }

    @Test("View My Bookings from Bookings resets Bookings once")
    func viewMyBookingsFromBookings() {
        let exit = HomeShellExit.plan(.viewMyBookings, selectedTab: .bookings)
        #expect(exit.resetTabs == [.bookings])
        #expect(exit.resetTabs.count == 1)
    }

    @Test("View My Bookings from Profile resets Profile and Bookings")
    func viewMyBookingsFromProfile() {
        let exit = HomeShellExit.plan(.viewMyBookings, selectedTab: .profile)
        #expect(exit.resetTabs == [.profile, .bookings])
        #expect(exit.showTab == .bookings)
    }

    @Test("Back to Home from Explore resets Explore once")
    func backToHomeFromExplore() {
        let exit = HomeShellExit.plan(.backToHome, selectedTab: .explore)
        #expect(exit.resetTabs == [.explore])
        #expect(exit.showTab == .explore)
    }

    @Test("View My History resets the source tab and Bookings, shows Bookings on Past", arguments: HomeClientTab.allCases)
    func viewMyHistory(source: HomeClientTab) {
        let exit = HomeShellExit.plan(.viewMyHistory, selectedTab: source)
        #expect(exit.resetTabs == [source, .bookings])
        #expect(exit.showTab == .bookings)
        #expect(exit.showsPastBookings == true)
    }

    @Test("View My History from Profile resets Profile and Bookings")
    func viewMyHistoryFromProfile() {
        let exit = HomeShellExit.plan(.viewMyHistory, selectedTab: .profile)
        #expect(exit.resetTabs == [.profile, .bookings])
        #expect(exit.showTab == .bookings)
        #expect(exit.showsPastBookings)
    }

    @Test("View My History from Bookings resets Bookings once")
    func viewMyHistoryFromBookings() {
        let exit = HomeShellExit.plan(.viewMyHistory, selectedTab: .bookings)
        #expect(exit.resetTabs == [.bookings])
        #expect(exit.showTab == .bookings)
        #expect(exit.showsPastBookings)
    }

    @Test("Explore Experts from Profile resets Profile only, leaving Explore's stack")
    func exploreExpertsFromProfile() {
        let exit = HomeShellExit.plan(.backToHome, selectedTab: .profile)
        #expect(exit.resetTabs == [.profile])
        #expect(exit.resetTabs.contains(.explore) == false)
        #expect(exit.showTab == .explore)
        #expect(exit.showsPastBookings == false)
    }

    @Test("A double tap gives the same plan", arguments: HomeClientTab.allCases)
    func idempotent(source: HomeClientTab) {
        #expect(
            HomeShellExit.plan(.backToHome, selectedTab: source)
                == HomeShellExit.plan(.backToHome, selectedTab: source)
        )
        #expect(
            HomeShellExit.plan(.viewMyBookings, selectedTab: source)
                == HomeShellExit.plan(.viewMyBookings, selectedTab: source)
        )
    }
}
