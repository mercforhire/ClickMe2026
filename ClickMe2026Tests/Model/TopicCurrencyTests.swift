//
//  TopicCurrencyTests.swift
//  ClickMe2026Tests
//
//  Backend Phase 34 (USD topic pricing), D-18: editing a topic keeps the
//  topic's own currency. The old editor sent the account default (CAD) as soon
//  as the price was retyped, so a USD topic was silently re-saved as CAD. These
//  tests pin the pieces: `allowed_currencies` decoding, the currency the editor
//  starts on, the paid-topic lock, and the currency `validate()` sends.
//  Contract: `docs/ios/USD-TOPIC-PRICING.md` in the backend repo.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Topic currency (backend Phase 34)")
struct TopicCurrencyTests {

    // MARK: - allowed_currencies decoding (D-03)

    @Test("allowed_currencies decodes from /me pricing_limits")
    func decodesAllowedCurrencies() throws {
        let me = try Self.decoder().decode(MeData.self, from: Data(Self.meJSON(allowed: #""allowed_currencies":["CAD","USD"],"#).utf8))
        #expect(me.pricingLimits?.allowedCurrencies == ["CAD", "USD"])
        #expect(me.pricingLimits?.minSessionAmount.defaultCurrency == "CAD")
    }

    @Test("a /me without allowed_currencies still decodes, with nil")
    func decodesWithoutAllowedCurrencies() throws {
        let me = try Self.decoder().decode(MeData.self, from: Data(Self.meJSON(allowed: "").utf8))
        #expect(me.pricingLimits != nil)
        #expect(me.pricingLimits?.allowedCurrencies == nil)
    }

    // MARK: - Initial currency and lock rule (D-18, D-04)

    @Test("a paid USD topic starts on USD and is locked, on a CAD-default account")
    func paidUSDTopicStartsOnUSDAndLocks() throws {
        let topic = try Self.topic(Self.paidUSD)
        #expect(TopicEditorViewModel.resolveInitialCurrency(topic: topic, defaultCurrency: "CAD") == "USD")
        #expect(TopicEditorViewModel.isCurrencyLocked(topic: topic))
    }

    @Test("the topic's stored currency is uppercased")
    func storedCurrencyIsUppercased() throws {
        let topic = try Self.topic(Self.paidLowercaseUSD)
        #expect(TopicEditorViewModel.resolveInitialCurrency(topic: topic, defaultCurrency: "CAD") == "USD")
    }

    @Test("a free topic keeps its stored currency and is not locked")
    func freeTopicIsNotLocked() throws {
        let topic = try Self.topic(Self.freeCAD)
        #expect(TopicEditorViewModel.resolveInitialCurrency(topic: topic, defaultCurrency: "USD") == "CAD")
        #expect(!TopicEditorViewModel.isCurrencyLocked(topic: topic))
    }

    @Test("a new topic takes the default currency and is not locked")
    func newTopicTakesDefault() {
        #expect(TopicEditorViewModel.resolveInitialCurrency(topic: nil, defaultCurrency: "CAD") == "CAD")
        #expect(!TopicEditorViewModel.isCurrencyLocked(topic: nil))
    }

    @Test("a topic with no stored currency takes the default and is not locked")
    func topicWithoutCurrencyTakesDefault() throws {
        let topic = try Self.topic(Self.paidNoCurrency)
        #expect(TopicEditorViewModel.resolveInitialCurrency(topic: topic, defaultCurrency: "CAD") == "CAD")
        #expect(!TopicEditorViewModel.isCurrencyLocked(topic: topic))
    }

    // MARK: - View model state

    @Test("the view model holds the paid USD topic's currency and locks the picker")
    func viewModelHoldsTopicCurrency() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.paidUSD))
        #expect(vm.currency == "USD")
        #expect(vm.isCurrencyLocked)
        #expect(vm.currencySymbol == "US$")
        #expect(vm.showsUSDFXNotice)
        // The test host has no /me: allowed falls back to the default, and the
        // topic's own code is appended so the selection still renders.
        #expect(vm.allowedCurrencies == [vm.defaultCurrency])
        #expect(vm.pickableCurrencies.contains("USD"))
    }

    @Test("a new topic starts on the default currency, unlocked, without the USD notice")
    func newTopicViewModel() {
        let vm = TopicEditorViewModel(topic: nil)
        #expect(vm.currency == vm.defaultCurrency)
        #expect(!vm.isCurrencyLocked)
        #expect(!vm.showsUSDFXNotice)
        #expect(vm.pickableCurrencies == [vm.defaultCurrency])
    }

    @Test("selecting USD on a new topic shows the notice and the US$ label")
    func selectingUSDOnNewTopic() {
        let vm = TopicEditorViewModel(topic: nil)
        vm.currency = "USD"
        #expect(vm.showsUSDFXNotice)
        #expect(vm.currencySymbol == "US$")
        #expect(vm.pickableCurrencies.contains("USD"))
    }

    // MARK: - validate() sends the topic's own currency (the ROADMAP bug)

    @Test("a RETYPED price on a paid USD topic validates in USD on a CAD-default account")
    func retypedPriceKeepsUSD() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.paidUSD))
        vm.rate = "130"
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 13000)
        #expect(validated?.currency == "USD")
    }

    @Test("an UNTOUCHED price on a paid USD topic keeps the stored amount and USD")
    func untouchedPriceKeepsUSD() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.paidUSD))
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 12550)
        #expect(validated?.currency == "USD")
    }

    @Test("a free topic that picks USD and types a price validates in USD")
    func freeTopicPickingUSD() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.freeCAD))
        vm.currency = "USD"
        vm.rate = "25"
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 2500)
        #expect(validated?.currency == "USD")
    }

    // MARK: - Decimal prices and currency switching (EXP-02, D-03)

    @Test("switching currency keeps the typed number and re-prices it in the new currency")
    func currencySwitchKeepsTypedText() {
        let vm = TopicEditorViewModel(topic: nil)
        vm.title = "Portfolio review" // validate() checks the title before the price
        vm.currency = "CAD"
        vm.updateRate("12.50")

        vm.currency = "USD"
        #expect(vm.rate == "12.50")
        #expect(vm.validate()?.hourlyRateAmount == 1250)
        #expect(vm.validate()?.currency == "USD")

        vm.currency = "CAD"
        #expect(vm.rate == "12.50")
        #expect(vm.validate()?.hourlyRateAmount == 1250)
        #expect(vm.validate()?.currency == "CAD")
    }

    @Test("a comma decimal on a new topic saves as the same minor amount")
    func commaDecimalOnNewTopic() {
        let vm = TopicEditorViewModel(topic: nil)
        vm.title = "Portfolio review"
        vm.updateRate("12,50")
        #expect(vm.rate == "12,50")
        #expect(vm.validate()?.hourlyRateAmount == 1250)
    }

    @Test("a typed decimal on a paid USD topic validates in USD")
    func typedDecimalOnPaidUSDTopic() throws {
        let vm = TopicEditorViewModel(topic: try Self.topic(Self.paidUSD))
        vm.updateRate("130.25")
        let validated = vm.validate()
        #expect(validated?.hourlyRateAmount == 13025)
        #expect(validated?.currency == "USD")
    }

    @Test("a 20-digit paste is capped at 7 integer digits and never traps")
    func longPasteInEditor() {
        let vm = TopicEditorViewModel(topic: nil)
        vm.title = "Portfolio review"
        vm.updateRate(String(repeating: "9", count: 20))
        #expect(vm.rate == "9999999")
        #expect(vm.validate()?.hourlyRateAmount == 999_999_900)
    }

    @Test("a third fraction digit is dropped as the expert types")
    func thirdFractionDigitDropped() {
        let vm = TopicEditorViewModel(topic: nil)
        vm.updateRate("12.505")
        #expect(vm.rate == "12.50")
    }

    @Test("untouched seeds round-trip: 1250 seeds 12.50, 1200 seeds 12")
    func untouchedSeedsRoundTrip() throws {
        let cents = TopicEditorViewModel(topic: try Self.topic(Self.paidCAD1250))
        #expect(cents.rate == "12.50")
        #expect(cents.validate()?.hourlyRateAmount == 1250)
        #expect(cents.validate()?.currency == "CAD")

        let whole = TopicEditorViewModel(topic: try Self.topic(Self.paidCAD1200))
        #expect(whole.rate == "12")
        #expect(whole.validate()?.hourlyRateAmount == 1200)
        #expect(whole.validate()?.currency == "CAD")
    }

    // MARK: - Fixtures

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    private static func topic(_ json: String) throws -> ExpertTopicItem {
        try decoder().decode(ExpertTopicItem.self, from: Data(json.utf8))
    }

    private static func meJSON(allowed: String) -> String {
        """
        {
          "id": "55555555-5555-5555-5555-555555555555",
          "email": "expert@example.com",
          "roles": ["client", "expert"],
          "pricing_limits": {
            \(allowed)
            "min_session_amount": {
              "by_currency": { "USD": 500, "CAD": 500 },
              "default_minor_units": 500,
              "default_currency": "CAD"
            }
          }
        }
        """
    }

    private static let paidUSD = """
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "title": "Portfolio review",
      "price": { "amount": 12550, "currency": "USD", "is_free": false },
      "hourly_rate": { "amount": 12550, "currency": "USD" }
    }
    """

    private static let paidLowercaseUSD = """
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "title": "Portfolio review",
      "price": { "amount": 12550, "currency": "usd", "is_free": false },
      "hourly_rate": { "amount": 12550, "currency": "usd" }
    }
    """

    private static let paidCAD1250 = """
    {
      "id": "66666666-6666-6666-6666-666666666666",
      "title": "Portfolio review",
      "price": { "amount": 1250, "currency": "CAD", "is_free": false },
      "hourly_rate": { "amount": 1250, "currency": "CAD" }
    }
    """

    private static let paidCAD1200 = """
    {
      "id": "77777777-7777-7777-7777-777777777777",
      "title": "Portfolio review",
      "price": { "amount": 1200, "currency": "CAD", "is_free": false },
      "hourly_rate": { "amount": 1200, "currency": "CAD" }
    }
    """

    private static let freeCAD = """
    {
      "id": "33333333-3333-3333-3333-333333333333",
      "title": "Intro chat",
      "price": { "amount": 500, "currency": "CAD", "is_free": true }
    }
    """

    private static let paidNoCurrency = """
    {
      "id": "44444444-4444-4444-4444-444444444444",
      "title": "Portfolio review",
      "price": { "amount": 12550, "is_free": false }
    }
    """
}
