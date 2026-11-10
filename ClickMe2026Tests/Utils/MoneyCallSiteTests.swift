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

    // MARK: - Earnings transaction rows (minor units)

    @Test("earnings transaction rows keep their cents and honor zero-decimal currencies")
    func earningsTransactionRows() {
        #expect(EarningsTransactionRow.formatMinorUnits(1200, currency: "JPY") == "¥1200")
        #expect(EarningsTransactionRow.formatMinorUnits(1250, currency: "USD") == "$12.50")
    }

    // MARK: - Topic editor price seed (D-11) and untouched save (D-19)

    @Test("the editable price seed keeps cents and uses the currency's digit count")
    func editablePriceSeed() {
        #expect(TopicEditorViewModel.editableAmount(minorUnits: 1250, currency: "USD") == "12.50")
        #expect(TopicEditorViewModel.editableAmount(minorUnits: 1205, currency: "CAD") == "12.05")
        #expect(TopicEditorViewModel.editableAmount(minorUnits: 1200, currency: "USD") == "12")
        #expect(TopicEditorViewModel.editableAmount(minorUnits: 0, currency: "USD") == "0")
        #expect(TopicEditorViewModel.editableAmount(minorUnits: 1200, currency: "JPY") == "1200")
        #expect(TopicEditorViewModel.editableAmount(minorUnits: 12550, currency: "usd") == "125.50")
    }

    @Test("an untouched 12550 USD topic saves its stored amount and stored currency")
    func untouchedUSDTopicKeepsAmountAndCurrency() throws {
        // In the test host with no cached profile `defaultCurrency` is "CAD",
        // so this is a USD topic on a CAD-default account (D-19).
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.hourlyRate12550USD))
        #expect(vm.rate == "125.50")

        let untouched = vm.validate()
        #expect(untouched?.hourlyRateAmount == 12550)
        #expect(untouched?.currency == "USD")

        vm.rate = " 125.50 "
        let padded = vm.validate()
        #expect(padded?.hourlyRateAmount == 12550)
        #expect(padded?.currency == "USD")
    }

    @Test("a typed whole number is still parsed and priced in the default currency")
    func typedWholeNumberUsesDefaultCurrency() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.hourlyRate12550USD))
        vm.rate = "130"
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 13000)
        #expect(validated?.currency == vm.defaultCurrency)
    }

    @Test("typed decimal input is still rejected until Phase 6")
    func typedDecimalIsRejected() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.hourlyRate12550USD))
        vm.rate = "130.50"
        #expect(vm.validate() == nil)
    }

    @Test("a whole-dollar hourly rate seeds as a plain integer and saves unchanged")
    func wholeHourlyRateRoundTrip() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.hourlyRate12500USD))
        #expect(vm.rate == "125")
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 12500)
        #expect(validated?.currency == "USD")
    }

    @Test("a topic with only a price falls back to the price amount and currency")
    func priceOnlyTopicRoundTrip() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.priceOnly12550CAD))
        #expect(vm.rate == "125.50")
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 12550)
        #expect(validated?.currency == "CAD")
    }

    @Test("a topic with no stored currency saves untouched in the default currency")
    func priceWithoutCurrencyUsesDefault() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.priceOnly12550NoCurrency))
        #expect(vm.rate == "125.50")
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 12550)
        #expect(validated?.currency == vm.defaultCurrency)
    }

    @Test("a new topic seeds an empty price and parses a typed whole number")
    func newTopicSeed() {
        let vm = TopicEditorViewModel(topic: nil)
        #expect(vm.rate == "")
        vm.title = "Portfolio review" // validate() checks the title before the price
        vm.rate = "150"
        #expect(vm.validate()?.hourlyRateAmount == 15000)
    }

    // MARK: - Fixtures

    private static func topic(_ json: String) throws -> ExpertTopicItem {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ExpertTopicItem.self, from: Data(json.utf8))
    }

    private static let hourlyRate12550USD = """
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "title": "Portfolio review",
      "price": { "amount": 12550, "currency": "USD", "is_free": false },
      "hourly_rate": { "amount": 12550, "currency": "USD" }
    }
    """

    private static let hourlyRate12500USD = """
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "title": "Portfolio review",
      "price": { "amount": 12500, "currency": "USD", "is_free": false },
      "hourly_rate": { "amount": 12500, "currency": "USD" }
    }
    """

    private static let priceOnly12550CAD = """
    {
      "id": "33333333-3333-3333-3333-333333333333",
      "title": "Portfolio review",
      "price": { "amount": 12550, "currency": "CAD", "is_free": false }
    }
    """

    private static let priceOnly12550NoCurrency = """
    {
      "id": "44444444-4444-4444-4444-444444444444",
      "title": "Portfolio review",
      "price": { "amount": 12550, "is_free": false }
    }
    """
}
