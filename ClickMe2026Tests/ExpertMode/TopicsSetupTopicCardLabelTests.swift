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

    @Test("card and editor agree on a paid topic that carries no currency")
    func cardAndEditorAgreeOnBlankCurrency() throws {
        let topic = try Self.topic(
            price: #"{"amount":12500,"currency":"","is_free":false,"label":"$125 / session"}"#
        )
        let editor = TopicEditorViewModel(topic: topic)
        let defaultCurrency = TopicEditorViewModel.newTopicDefaultCurrency(in: UserManager.shared.me)
        let card = TopicsSetupTopicCard.priceLabel(for: topic, defaultCurrency: defaultCurrency)

        #expect(editor.currency == "CAD")
        #expect(editor.currencySymbol == "CA$")
        #expect(card == "CA$125.00 / session")
        #expect(card.hasPrefix(editor.currencySymbol))
    }
}
