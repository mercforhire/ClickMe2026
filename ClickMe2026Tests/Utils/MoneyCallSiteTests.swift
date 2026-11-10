//
//  MoneyCallSiteTests.swift
//  ClickMe2026Tests
//
//  Pins the unit each expert money site passes to the shared formatter
//  (BOOK-10). The server sends some fields in minor units and others already
//  divided into major units, so a site that uses the wrong entry point shows
//  an amount scaled by 100. These rows fail if a site drops cents, takes the
//  device-locale symbol, or mixes the two units up.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Money call sites")
struct MoneyCallSiteTests {

    // MARK: - Expert dashboard and Payouts balances (minor units)

    @Test("expert dashboard earnings and payout labels keep their cents")
    func expertDashboardBalances() {
        #expect(ExpertDashboardViewModel.currencyLabel(minorUnits: 1250, currency: "USD") == "$12.50")
        #expect(ExpertDashboardViewModel.currencyLabel(minorUnits: 12000, currency: "USD") == "$120.00")
    }

    @Test("payouts balances keep their cents and use fixed symbols")
    func payoutsBalances() {
        #expect(PayoutsViewModel.currencyLabel(minorUnits: 1200, currency: "CAD") == "CA$12.00")
        #expect(PayoutsViewModel.currencyLabel(minorUnits: 5000, currency: "JPY") == "¥5000")
    }

    // MARK: - Earnings the server already divided into major units

    @Test("incoming request earnings keep their cents and keep the dash for missing values")
    func incomingRequestEarnings() {
        #expect(IncomingRequestsViewModel.formatEarnings(amountMajor: 75.0, currency: "USD") == "$75.00")
        #expect(IncomingRequestsViewModel.formatEarnings(amountMajor: 75.5, currency: "USD") == "$75.50")
        #expect(IncomingRequestsViewModel.formatEarnings(amountMajor: nil, currency: "USD") == "—")
        #expect(IncomingRequestsViewModel.formatEarnings(amountMajor: 75.0, currency: nil) == "—")
    }

    @Test("upcoming session net earnings use the major entry point and hide a bad value")
    func upcomingSessionEarnings() {
        #expect(UpcomingBookingsViewModel.formatCurrency(75.5, code: "USD") == "$75.50")
        #expect(UpcomingBookingsViewModel.formatCurrency(.nan, code: "USD") == nil)
    }
}
