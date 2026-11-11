//
//  MyBookingsEmptyStateTests.swift
//  ClickMe2026Tests
//
//  BOOK-11 (UI-SPEC EM1): the Past tab shows its empty state only when the
//  load succeeded and there are no past bookings. Pure rows: no API, so no
//  APITestFactory.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("My Bookings empty states")
struct MyBookingsEmptyStateTests {

    @Test("Past tab, loaded, no past bookings shows the empty state")
    func pastTabEmpty() {
        let viewModel = MyBookingsViewModel.previewSeed(selectedTab: 1, pastBookings: [])

        #expect(viewModel.showsPastEmptyState)
    }

    @Test("Upcoming tab never shows the Past empty state")
    func upcomingTabEmpty() {
        let viewModel = MyBookingsViewModel.previewSeed(selectedTab: 0, pastBookings: [])

        #expect(!viewModel.showsPastEmptyState)
    }

    @Test("Past tab with a past booking shows the list, not the empty state")
    func pastTabWithBooking() {
        let viewModel = MyBookingsViewModel.previewSeed(selectedTab: 1)
        #expect(!viewModel.pastBookings.isEmpty)

        #expect(!viewModel.showsPastEmptyState)
    }

    @Test("no empty state while loading or before the first load")
    func notWhileLoading() {
        let viewModel = MyBookingsViewModel.previewSeed(selectedTab: 1, pastBookings: [])

        viewModel.state = .loading
        #expect(!viewModel.showsPastEmptyState)

        viewModel.state = .idle
        #expect(!viewModel.showsPastEmptyState)
    }

    @Test("no empty state after a failed load")
    func notAfterFailure() {
        let viewModel = MyBookingsViewModel.previewSeed(selectedTab: 1, pastBookings: [])

        viewModel.state = .failed("Couldn't load bookings")

        #expect(!viewModel.showsPastEmptyState)
    }
}
