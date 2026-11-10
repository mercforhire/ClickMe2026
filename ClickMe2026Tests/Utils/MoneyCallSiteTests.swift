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
}
