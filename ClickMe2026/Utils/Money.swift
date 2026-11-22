//
//  Money.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The one place a client-visible price is turned into text (BOOK-10).
///
/// Amounts arrive from the server as integer minor units plus an ISO 4217
/// code, so the minor path here uses integer arithmetic only. No floating
/// point is involved, which means the text a client reads is exactly the
/// amount the server will hold or charge.
///
/// Rules:
/// - Full minor digits always: `US$12.00` stays `US$12.00`, never `US$12`.
/// - Symbols come from a fixed table, never from the device region and never
///   from a system currency formatter (D-10). `US$` is USD and `CA$` is CAD, so
///   the two can't be confused on a Canadian or American phone (D-24, and
///   `docs/ios/USD-TOPIC-PRICING.md` section 0 item 5). Any code
///   outside the table is shown as the ISO code, then a non-breaking space.
/// - Digits follow the backend's zero-decimal set (`src/utils/earnings.js`),
///   because the server computes minor units with that same set. A currency
///   the backend treats as 2-digit is formatted with 2 digits here too.
///
/// `format(major:currency:)` exists only for fields the server has already
/// divided into major units. Prefer the minor entry point everywhere else.
nonisolated enum Money {

    // MARK: - Tables

    /// Currencies with no minor unit. Mirrors the backend set exactly.
    private static let zeroDecimal: Set<String> = ["JPY", "KRW", "VND", "CLP", "ISK", "XOF", "XAF"]

    /// Display symbols. Mirrors `src/utils/pricing.js`, except that CHF and any
    /// unlisted code print the ISO code (see `prefix(for:)`).
    private static let symbols: [String: String] = [
        "USD": "US$",
        "CAD": "CA$",
        "AUD": "A$",
        "EUR": "€",
        "GBP": "£",
        "JPY": "¥",
        "INR": "₹"
    ]

    /// Separator placed between groups of three whole-part digits, or `nil` for
    /// none. Product decision (Open Question 1): no grouping for now. Setting
    /// this to `","` turns grouping on for every screen in one step.
    static let thousandsSeparator: String? = nil

    // MARK: - Helpers

    /// Number of digits after the decimal point: 0 for the backend's
    /// zero-decimal set, otherwise 2. The code is trimmed and upper-cased.
    static func fractionDigits(for currency: String) -> Int {
        zeroDecimal.contains(normalized(currency)) ? 0 : 2
    }

    /// Text placed before the number. The table symbol for a known currency,
    /// nothing for an empty code, otherwise the ISO code followed by U+00A0 so
    /// the code and number never wrap onto separate lines.
    static func prefix(for currency: String) -> String {
        let code = normalized(currency)
        if code.isEmpty { return "" }
        if let symbol = symbols[code] { return symbol }
        return code + "\u{00A0}"
    }

    /// Writes `value` in decimal, inserting `separator` between groups of three
    /// digits when one is given.
    static func groupWhole(_ value: UInt, separator: String?) -> String {
        let digits = String(value)
        guard let separator, digits.count > 3 else { return digits }
        var groups: [Substring] = []
        var end = digits.endIndex
        while end > digits.startIndex {
            let start = digits.index(end, offsetBy: -3, limitedBy: digits.startIndex) ?? digits.startIndex
            groups.append(digits[start..<end])
            end = start
        }
        return groups.reversed().joined(separator: separator)
    }

    private static func normalized(_ currency: String) -> String {
        currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private static func power10(_ exponent: Int) -> UInt {
        var result: UInt = 1
        for _ in 0..<exponent { result *= 10 }
        return result
    }

    // MARK: - Formatting

    /// Formats an amount in minor units, for example `1250` and `"USD"` give
    /// `"US$12.50"`. Integer arithmetic only. The sign goes before the symbol
    /// (`-US$12.50`). `Int.min` and `Int.max` format without trapping because the
    /// magnitude is taken as an unsigned value.
    static func format(minorUnits: Int, currency: String) -> String {
        let digits = fractionDigits(for: currency)
        let divisor = power10(digits)
        let magnitude = minorUnits.magnitude
        let whole = magnitude / divisor
        let fraction = magnitude % divisor

        var text = minorUnits < 0 ? "-" : ""
        text += prefix(for: currency)
        text += groupWhole(whole, separator: thousandsSeparator)
        if digits > 0 {
            let padded = String(fraction)
            text += "." + String(repeating: "0", count: digits - padded.count) + padded
        }
        return text
    }

    /// Formats an amount the server already expressed in major units, for
    /// example `75.5` and `"USD"` give `"US$75.50"`. Rounds half away from zero
    /// at the currency's last digit. Returns `nil` for a non-finite value or
    /// one too large to represent, so a bad payload can't crash the screen.
    static func format(major: Double, currency: String) -> String? {
        guard major.isFinite else { return nil }
        let scaled = major * Double(power10(fractionDigits(for: currency)))
        guard abs(scaled) <= 9.0e15 else { return nil }
        return format(minorUnits: Int(scaled.rounded()), currency: currency)
    }
}
