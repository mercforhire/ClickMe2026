//
//  MoneyTests.swift
//  ClickMe2026Tests
//
//  Pins the shared money formatter (BOOK-10). A client once saw "USD 12" for a
//  1250-cent price because of an integer divide by 100, and a CAD price shown
//  with a bare "$" because the symbol came from the device region. These
//  tables fail if cents are dropped, a symbol changes, or a boundary traps.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Money")
struct MoneyTests {

    private static let nbsp = "\u{00A0}"

    // MARK: - Tables

    nonisolated struct MinorCase: Sendable, CustomTestStringConvertible {
        let minor: Int
        let currency: String
        let expected: String
        var testDescription: String { "\(minor) \(currency) -> \(expected)" }
    }

    private static let symbolRows: [MinorCase] = [
        MinorCase(minor: 1250, currency: "USD", expected: "US$12.50"),
        MinorCase(minor: 1200, currency: "USD", expected: "US$12.00"),
        MinorCase(minor: 1250, currency: "CAD", expected: "CA$12.50"),
        MinorCase(minor: 1200, currency: "JPY", expected: "¥1200"),
        MinorCase(minor: 1250, currency: "EUR", expected: "€12.50"),
        MinorCase(minor: 1250, currency: "GBP", expected: "£12.50"),
        MinorCase(minor: 1250, currency: "AUD", expected: "A$12.50"),
        MinorCase(minor: 1250, currency: "INR", expected: "₹12.50")
    ]

    private static let boundaryRows: [MinorCase] = [
        MinorCase(minor: 0, currency: "USD", expected: "US$0.00"),
        MinorCase(minor: 1, currency: "USD", expected: "US$0.01"),
        MinorCase(minor: 5, currency: "USD", expected: "US$0.05"),
        MinorCase(minor: 99, currency: "USD", expected: "US$0.99"),
        MinorCase(minor: 100, currency: "USD", expected: "US$1.00"),
        MinorCase(minor: 123_456_789, currency: "USD", expected: "US$1234567.89")
    ]

    private static let signAndCaseRows: [MinorCase] = [
        MinorCase(minor: -1250, currency: "USD", expected: "-US$12.50"),
        MinorCase(minor: -5, currency: "CAD", expected: "-CA$0.05"),
        MinorCase(minor: 1250, currency: "usd", expected: "US$12.50"),
        MinorCase(minor: 1250, currency: " cad ", expected: "CA$12.50")
    ]

    private static let codeRows: [MinorCase] = [
        MinorCase(minor: 1250, currency: "CHF", expected: "CHF\(nbsp)12.50"),
        MinorCase(minor: 1250, currency: "XYZ", expected: "XYZ\(nbsp)12.50"),
        MinorCase(minor: 5000, currency: "KRW", expected: "KRW\(nbsp)5000"),
        MinorCase(minor: 1250, currency: "", expected: "12.50")
    ]

    private static let zeroDecimalCodes = ["JPY", "KRW", "VND", "CLP", "ISK", "XOF", "XAF"]
    private static let twoDigitCodes = ["USD", "CAD", "EUR", "GBP", "AUD", "INR", "CHF", "KWD", "BHD", "XYZ", ""]

    // MARK: - format(minorUnits:currency:)

    @Test("known symbols keep full cents", arguments: Self.symbolRows)
    func symbols(row: MinorCase) {
        #expect(Money.format(minorUnits: row.minor, currency: row.currency) == row.expected)
    }

    @Test("boundary amounts", arguments: Self.boundaryRows)
    func boundaries(row: MinorCase) {
        #expect(Money.format(minorUnits: row.minor, currency: row.currency) == row.expected)
    }

    @Test("sign goes before the symbol; code is trimmed and case-insensitive", arguments: Self.signAndCaseRows)
    func signAndCase(row: MinorCase) {
        #expect(Money.format(minorUnits: row.minor, currency: row.currency) == row.expected)
    }

    @Test("unlisted codes show the ISO code and a non-breaking space; empty code has no prefix", arguments: Self.codeRows)
    func isoCodeFallback(row: MinorCase) {
        #expect(Money.format(minorUnits: row.minor, currency: row.currency) == row.expected)
    }

    @Test("Int.max and Int.min do not trap")
    func extremes() {
        let high = Money.format(minorUnits: Int.max, currency: "USD")
        let low = Money.format(minorUnits: Int.min, currency: "USD")
        #expect(high == "US$92233720368547758.07")
        #expect(low == "-US$92233720368547758.08")
        #expect(Money.format(minorUnits: Int.max, currency: "JPY") == "¥9223372036854775807")
        #expect(Money.format(minorUnits: Int.min, currency: "JPY").hasPrefix("-¥"))
    }

    @Test("whole amounts keep their zeros and no thousands separator is inserted")
    func noGroupingByDefault() {
        #expect(Money.thousandsSeparator == nil)
        #expect(Money.format(minorUnits: 1_200_000, currency: "USD") == "US$12000.00")
        #expect(Money.format(minorUnits: 100_000_000, currency: "JPY") == "¥100000000")
    }

    // MARK: - Digits

    @Test("zero-decimal currencies are exactly the backend set", arguments: Self.zeroDecimalCodes)
    func zeroDecimal(code: String) {
        #expect(Money.fractionDigits(for: code) == 0)
        #expect(Money.fractionDigits(for: code.lowercased()) == 0)
    }

    @Test("every other code has 2 digits, including 3-digit ICU currencies", arguments: Self.twoDigitCodes)
    func twoDigits(code: String) {
        #expect(Money.fractionDigits(for: code) == 2)
    }

    // MARK: - Prefix

    @Test("prefix table")
    func prefixes() {
        #expect(Money.prefix(for: "USD") == "US$")
        #expect(Money.prefix(for: "CAD") == "CA$")
        #expect(Money.prefix(for: "CHF") == "CHF\(Self.nbsp)")
        #expect(Money.prefix(for: "") == "")
        #expect(Money.prefix(for: "   ") == "")
    }

    // MARK: - format(major:currency:)

    @Test("major units round half away from zero")
    func majorRounding() {
        #expect(Money.format(major: 75.5, currency: "USD") == "US$75.50")
        #expect(Money.format(major: 75.0, currency: "USD") == "US$75.00")
        #expect(Money.format(major: 0.125, currency: "USD") == "US$0.13")
        #expect(Money.format(major: -0.125, currency: "USD") == "-US$0.13")
        #expect(Money.format(major: 12.0, currency: "JPY") == "¥12")
    }

    @Test("non-finite and out-of-range major values return nil", arguments: [Double.nan, .infinity, -.infinity, 1e300, -1e300])
    func majorRejectsBadValues(value: Double) {
        #expect(Money.format(major: value, currency: "USD") == nil)
    }

    // MARK: - groupWhole

    @Test("groupWhole inserts a separator only when asked")
    func grouping() {
        #expect(Money.groupWhole(1_234_567, separator: ",") == "1,234,567")
        #expect(Money.groupWhole(999, separator: ",") == "999")
        #expect(Money.groupWhole(1000, separator: ",") == "1,000")
        #expect(Money.groupWhole(0, separator: ",") == "0")
        #expect(Money.groupWhole(1_234_567, separator: nil) == "1234567")
    }

    // MARK: - BookingTopic

    @MainActor
    @Test("BookingTopic price label goes through Money")
    func bookingTopicLabel() {
        func topic(amount: Int?, currency: String?, isFree: Bool) -> BookingTopic {
            BookingTopic(
                id: UUID(),
                title: "Chat",
                durationMinutes: 30,
                description: nil,
                priceAmount: amount,
                currency: currency,
                isFree: isFree
            )
        }
        #expect(topic(amount: 1250, currency: "USD", isFree: false).priceLabel == "US$12.50")
        #expect(topic(amount: 1200, currency: "USD", isFree: false).priceLabel == "US$12.00")
        #expect(topic(amount: 1250, currency: "CAD", isFree: false).priceLabel == "CA$12.50")
        #expect(topic(amount: 1250, currency: "USD", isFree: true).priceLabel == "Free")
        #expect(topic(amount: nil, currency: "USD", isFree: false).priceLabel == "—")
        #expect(topic(amount: 1250, currency: nil, isFree: false).priceLabel == "—")
    }
}
