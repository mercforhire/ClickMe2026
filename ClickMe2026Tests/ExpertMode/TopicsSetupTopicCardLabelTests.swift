//
//  TopicsSetupTopicCardLabelTests.swift
//  ClickMe2026Tests
//
//  G-06-1-card-cents (UAT 06 Test 1, checklist item 1): the Topics tab card
//  shows the price to the cent, `CA$50.00 / session`, not the server label
//  `CA$50 / session` that `formatPrice.js` trims. The rows use the real wire
//  shape (`price` only, no `hourly_rate`, as since `50abd85`).
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Topics setup topic card label")
struct TopicsSetupTopicCardLabelTests {

    // MARK: - Fixtures

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    /// Wraps a `price` JSON object (and an optional extra top-level key) in
    /// the real wire shape of one `/expert/topics` item.
    private static func topic(price: String, extra: String = "") throws -> ExpertTopicItem {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "title": "Portfolio review",
          "duration_mins": 60,
          "description": "Old",
          "price": \(price),
          \(extra)
          "icon_slug": "marketing"
        }
        """
        return try decoder.decode(ExpertTopicItem.self, from: Data(json.utf8))
    }

    private static func label(_ topic: ExpertTopicItem, defaultCurrency: String = "CAD") -> String {
        TopicsSetupTopicCard.priceLabel(for: topic, defaultCurrency: defaultCurrency)
    }

    // MARK: - Paid, free, agreement with the editor

    @Test("a paid CAD topic reads CA$50.00 / session")
    func paidCAD() throws {
        let topic = try Self.topic(
            price: #"{"amount":5000,"currency":"CAD","is_free":false,"label":"CA$50 / session"}"#
        )
        #expect(Self.label(topic) == "CA$50.00 / session")
    }

    @Test("a paid USD topic keeps the US$ symbol and adds the cents")
    func paidUSD() throws {
        let topic = try Self.topic(
            price: #"{"amount":500,"currency":"USD","is_free":false,"label":"US$5 / session"}"#
        )
        #expect(Self.label(topic) == "US$5.00 / session")
    }

    @Test("a free topic reads Free")
    func free() throws {
        let topic = try Self.topic(price: #"{"amount":0,"currency":"","is_free":true,"label":"Free"}"#)
        #expect(Self.label(topic) == "Free")
    }

    @Test("card and editor agree on a paid topic that carries no currency, whatever the account default")
    func cardAndEditorAgreeOnBlankCurrency() throws {
        let topic = try Self.topic(
            price: #"{"amount":12500,"currency":"","is_free":false,"label":"$125 / session"}"#
        )
        // Each account is injected into the editor, so the result does not
        // depend on the state of the shared user manager (06-REVIEW IN-07).
        let usdDefault = try MeDataFixtures.me(defaultCurrency: "USD", allowedCurrencies: ["CAD", "USD"])
        let jpyDefault = try MeDataFixtures.me(defaultCurrency: "JPY", allowedCurrencies: ["CAD", "USD"])
        let cases: [(me: MeData?, currency: String, card: String)] = [
            (nil, "CAD", "CA$125.00 / session"),          // no /me yet
            (usdDefault, "USD", "US$125.00 / session"),   // default is pickable
            (jpyDefault, "CAD", "CA$125.00 / session")    // default not allowed: first allowed
        ]

        for testCase in cases {
            let me = testCase.me
            let editor = TopicEditorViewModel(topic: topic, meProvider: { me })
            let defaultCurrency = TopicEditorViewModel.newTopicDefaultCurrency(in: me)
            let card = TopicsSetupTopicCard.priceLabel(for: topic, defaultCurrency: defaultCurrency)

            #expect(editor.currency == testCase.currency)
            #expect(editor.defaultCurrency == testCase.currency)
            #expect(editor.rate == "125")
            #expect(card == testCase.card)
            #expect(card.hasPrefix(editor.currencySymbol))
        }
    }

    // MARK: - Fallbacks and tolerance

    @Test("amounts keep their cents and whole amounts keep two zeros")
    func centsAndWholeAmounts() throws {
        let cents = try Self.topic(
            price: #"{"amount":1250,"currency":"CAD","is_free":false,"label":"CA$12.5 / session"}"#
        )
        let whole = try Self.topic(
            price: #"{"amount":12000,"currency":"CAD","is_free":false,"label":"CA$120 / session"}"#
        )
        #expect(Self.label(cents) == "CA$12.50 / session")
        #expect(Self.label(whole) == "CA$120.00 / session")
    }

    @Test("a free topic reads Free whatever amount and currency it carries")
    func freeIgnoresAmount() throws {
        let topic = try Self.topic(
            price: #"{"amount":500,"currency":"CAD","is_free":true,"label":"Free"}"#
        )
        #expect(Self.label(topic) == "Free")
    }

    @Test("a paid topic with a blank currency is formatted in the editor's default, never the trimmed label")
    func blankCurrencyFollowsDefault() throws {
        let topic = try Self.topic(
            price: #"{"amount":12550,"currency":"","is_free":false,"label":"$125.5 / session"}"#
        )
        #expect(Self.label(topic, defaultCurrency: "CAD") == "CA$125.50 / session")
        #expect(Self.label(topic, defaultCurrency: "USD") == "US$125.50 / session")
    }

    @Test("a paid topic with no amount keeps the server label")
    func missingAmountKeepsLabel() throws {
        let topic = try Self.topic(
            price: #"{"amount":null,"currency":"CAD","is_free":false,"label":"CA$50 / session"}"#
        )
        #expect(Self.label(topic) == "CA$50 / session")
    }

    @Test("a paid topic with no amount and no label reads empty")
    func missingAmountAndLabelReadsEmpty() throws {
        let topic = try Self.topic(price: #"{"amount":null,"currency":"","is_free":false}"#)
        #expect(Self.label(topic) == "")
    }

    @Test("a lowercase currency code is normalized")
    func lowercaseCurrency() throws {
        let topic = try Self.topic(
            price: #"{"amount":5000,"currency":"cad","is_free":false,"label":"CA$50 / session"}"#
        )
        #expect(Self.label(topic) == "CA$50.00 / session")
    }

    @Test("an hourly rate on the payload is formatted the same way")
    func hourlyRateBranch() throws {
        let topic = try Self.topic(
            price: #"{"amount":18050,"currency":"USD","is_free":false,"label":"US$180.5 / session"}"#,
            extra: #""hourly_rate": {"amount":18050,"currency":"USD"},"#
        )
        #expect(Self.label(topic) == "US$180.50 / session")
    }

    @Test("a free topic with a null currency decodes and reads Free")
    func freeNullCurrency() throws {
        let topic = try Self.topic(price: #"{"amount":0,"currency":null,"is_free":true,"label":"Free"}"#)
        #expect(topic.storedCurrency == nil)
        #expect(Self.label(topic) == "Free")
    }

    @Test("a paid topic with a null currency decodes and is formatted in the editor's default")
    func paidNullCurrency() throws {
        let topic = try Self.topic(
            price: #"{"amount":5000,"currency":null,"is_free":false,"label":"CA$50 / session"}"#
        )
        #expect(topic.storedCurrency == nil)
        #expect(Self.label(topic, defaultCurrency: "CAD") == "CA$50.00 / session")
    }

    @Test("a negative amount keeps the server label")
    func negativeAmountKeepsLabel() throws {
        let topic = try Self.topic(
            price: #"{"amount":-500,"currency":"USD","is_free":false,"label":"US$5 / session"}"#
        )
        #expect(Self.label(topic) == "US$5 / session")
    }
}
