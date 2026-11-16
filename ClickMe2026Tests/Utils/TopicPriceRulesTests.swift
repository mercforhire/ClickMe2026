//
//  TopicPriceRulesTests.swift
//  ClickMe2026Tests
//
//  Pins the topic price field rules (EXP-02, D-05): what the field keeps as
//  the expert types, how the text becomes minor units in the topic's own
//  currency, and the floor check. The parse is integer arithmetic only, so
//  every accepted string maps to exactly one minor amount, and a long paste
//  cannot trap (04-VERIFICATION WR-03).
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Topic price rules")
struct TopicPriceRulesTests {

    // MARK: - parseMinor

    @Test("a typed price parses to the exact minor amount", arguments: [
        ("12.50", "CAD", 1250),
        ("12,50", "CAD", 1250),
        ("12.5", "CAD", 1250),
        (".5", "CAD", 50),
        ("12.", "CAD", 1200),
        ("12", "CAD", 1200),
        ("0.01", "USD", 1),
        ("130.50", "USD", 13050),
        (" 12.50 ", "CAD", 1250),
        ("9999999.99", "CAD", 999_999_999),
        ("1200", "JPY", 1200)
    ])
    func parsesValidPrices(text: String, currency: String, expected: Int) {
        #expect(TopicPriceRules.parseMinor(text, currency: currency) == expected)
    }

    @Test("blank and zero are a free session", arguments: ["", "  ", "0", "0.00", "00"])
    func blankAndZeroAreFree(text: String) {
        #expect(TopicPriceRules.parseMinor(text, currency: "CAD") == 0)
    }

    @Test("a price the currency cannot represent is rejected", arguments: [
        "12.505", "1.2.3", "abc", "-5", ".", ",", "12345678", "1 2", "1e3", "١٢"
    ])
    func rejectsInvalidPrices(text: String) {
        #expect(TopicPriceRules.parseMinor(text, currency: "CAD") == nil)
    }

    @Test("a zero-decimal currency takes whole units only")
    func zeroDecimalCurrency() {
        #expect(TopicPriceRules.parseMinor("1200", currency: "JPY") == 1200)
        #expect(TopicPriceRules.parseMinor("12.5", currency: "JPY") == nil)
    }

    @Test("a 20-digit paste is rejected without trapping")
    func longPasteDoesNotTrap() {
        let twentyDigits = String(repeating: "9", count: 20)
        #expect(TopicPriceRules.parseMinor(twentyDigits, currency: "CAD") == nil)
        #expect(TopicPriceRules.parseMinor(twentyDigits + ".99", currency: "USD") == nil)
        #expect(TopicPriceRules.parseMinor(twentyDigits, currency: "JPY") == nil)
    }

    // MARK: - filterInput

    @Test("the field keeps digits, one separator and the currency's fraction digits", arguments: [
        ("12.505", "CAD", "12.50"),
        ("12,50", "CAD", "12,50"),
        ("1a2.3b", "CAD", "12.3"),
        ("12345678", "CAD", "1234567"),
        ("1.2.3", "CAD", "1.23"),
        ("12.5", "JPY", "12"),
        ("", "CAD", ""),
        ("-5", "CAD", "5"),
        ("١٢", "CAD", "")
    ])
    func filtersTypedInput(raw: String, currency: String, expected: String) {
        #expect(TopicPriceRules.filterInput(raw, currency: currency) == expected)
    }

    @Test("a 20-digit paste keeps 7 integer digits")
    func longPasteIsCapped() {
        let twentyDigits = String(repeating: "7", count: 20)
        #expect(TopicPriceRules.filterInput(twentyDigits, currency: "CAD") == "7777777")
    }

    // MARK: - isBelowFloor

    @Test("a typed price is flagged below a CA$5.00 floor only when paid and under it", arguments: [
        ("4.99", true),
        ("0.01", true),
        ("5", false),
        ("5.00", false),
        ("5.01", false),
        ("", false),
        ("0", false),
        ("abc", false),
        ("99999999999999999999", false)
    ])
    func liveFloorCheck(text: String, expected: Bool) {
        #expect(TopicPriceRules.isBelowFloor(rateText: text, currency: "CAD", floorMinor: 500) == expected)
    }

    @Test("a missing floor is never below")
    func missingFloor() {
        #expect(TopicPriceRules.isBelowFloor(rateText: "0.01", currency: "CAD", floorMinor: nil) == false)
    }

    @Test("the minor overload exempts free and exact-floor prices")
    func minorFloor() {
        #expect(TopicPriceRules.isBelowFloor(minor: 499, floorMinor: 500))
        #expect(TopicPriceRules.isBelowFloor(minor: 0, floorMinor: 500) == false)
        #expect(TopicPriceRules.isBelowFloor(minor: 500, floorMinor: 500) == false)
    }
}
