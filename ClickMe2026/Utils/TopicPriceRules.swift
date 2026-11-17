//
//  TopicPriceRules.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-16.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Pure price rules for the topic editor: what the price field keeps as the
/// expert types, how the text becomes minor units, and the floor check.
///
/// Mirrors Android `TopicPrice.kt` (`filterInput`, `parse`). Every function is
/// integer arithmetic over ASCII digits: no floating point, no
/// string-to-decimal conversion, no parsed whole number multiplied by 100. An
/// accepted string therefore maps to exactly one minor amount with no
/// rounding, and a long paste cannot overflow (04-VERIFICATION WR-03).
///
/// The digit count after the separator comes from `Money.fractionDigits(for:)`
/// (D-05), so a zero-decimal currency takes whole units only. The server floor
/// (`PRICE_BELOW_MINIMUM`) stays authoritative; the floor check here is UX.
nonisolated enum TopicPriceRules {

    /// Most integer digits the field keeps. Caps the amount at 9,999,999 major
    /// units, which stays far inside the server's INTEGER maximum of
    /// 2147483647 minor units.
    static let maxIntegerDigits = 7

    // MARK: - Input filter

    /// What the field keeps as the expert types or pastes: ASCII digits plus at
    /// most one separator (`.` or `,`, whichever the keyboard typed). Integer
    /// digits past `maxIntegerDigits` and fraction digits past the currency's
    /// digit count are dropped. A zero-decimal currency stops at the separator,
    /// dropping it and everything after.
    /// - Parameters:
    ///   - raw: The text the field now holds.
    ///   - currency: ISO 4217 code of the topic's currency.
    static func filterInput(_ raw: String, currency: String) -> String {
        let digits = Money.fractionDigits(for: currency)
        var kept = ""
        var integerCount = 0
        var fractionCount = 0
        var separatorSeen = false
        for character in raw {
            if isASCIIDigit(character) {
                if !separatorSeen {
                    guard integerCount < maxIntegerDigits else { continue }
                    kept.append(character)
                    integerCount += 1
                } else if fractionCount < digits {
                    kept.append(character)
                    fractionCount += 1
                }
            } else if (character == "." || character == ","), !separatorSeen {
                if digits == 0 { return kept }
                kept.append(character)
                separatorSeen = true
            }
        }
        return kept
    }

    // MARK: - Parse

    /// Parses the typed text into minor units of `currency`. `,` reads as `.`.
    /// Returns 0 for blank text (a free session), `nil` for anything the
    /// currency cannot represent: a non-digit, a second separator, a lone
    /// separator, more integer digits than `maxIntegerDigits`, or more fraction
    /// digits than the currency has. Total: it cannot trap.
    /// - Parameters:
    ///   - text: The price field text, major units with an optional fraction.
    ///   - currency: ISO 4217 code of the topic's currency.
    static func parseMinor(_ text: String, currency: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }

        let digits = Money.fractionDigits(for: currency)
        let parts = trimmed
            .replacingOccurrences(of: ",", with: ".")
            .split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return nil }

        let whole = parts[0]
        let fraction = parts.count == 2 ? parts[1] : Substring("")
        guard whole.allSatisfy(isASCIIDigit), fraction.allSatisfy(isASCIIDigit) else { return nil }
        guard whole.count <= maxIntegerDigits, fraction.count <= digits else { return nil }
        guard !(whole.isEmpty && fraction.isEmpty) else { return nil }

        // At most 7 + 2 digits are folded in, so the result is at most 999,999,999.
        let paddedFraction = fraction + String(repeating: "0", count: digits - fraction.count)
        var minor = 0
        for character in whole + paddedFraction {
            minor = minor * 10 + digitValue(character)
        }
        return minor
    }

    // MARK: - Floor check

    /// True only for a paid amount under the floor. A free price (0) is exempt.
    /// - Parameters:
    ///   - minor: The parsed amount in minor units.
    ///   - floorMinor: The currency's minimum in minor units.
    static func isBelowFloor(minor: Int, floorMinor: Int) -> Bool {
        minor > 0 && minor < floorMinor
    }

    /// Live-hint variant of the floor check on the raw field text, using the
    /// same parse as Save. A free price is exempt, and an invalid price is
    /// reported on Save, not live, so both are `false` here. A `nil` floor
    /// (limits not loaded) is never below.
    /// - Parameters:
    ///   - rateText: The price field text.
    ///   - currency: ISO 4217 code of the topic's currency.
    ///   - floorMinor: The currency's minimum in minor units, or nil.
    static func isBelowFloor(rateText: String, currency: String, floorMinor: Int?) -> Bool {
        guard let floorMinor, let minor = parseMinor(rateText, currency: currency) else { return false }
        return isBelowFloor(minor: minor, floorMinor: floorMinor)
    }

    // MARK: - Stored currency (G-06-1-currency)

    /// The stored currency code a topic really carries, or nil. Trims
    /// whitespace and newlines, then accepts only exactly three ASCII letters
    /// and returns them uppercased. Blank, whitespace-only and malformed codes
    /// all read as no currency.
    ///
    /// Mirrors Android `TopicPrice.validCode`. The backend sends
    /// `price.currency: ""` for a topic stored with no currency
    /// (`expertTopics.controller.js` `serializeTopic`), and a blank code on a
    /// save is a 422. The server allowlist (CAD, USD) stays authoritative.
    /// - Parameter raw: The code as the server sent it, or nil.
    static func validCurrencyCode(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let scalars = trimmed.unicodeScalars
        guard scalars.count == 3, scalars.allSatisfy(isASCIILetter) else { return nil }
        return trimmed.uppercased()
    }

    // MARK: - Helpers

    private static func isASCIILetter(_ scalar: Unicode.Scalar) -> Bool {
        (scalar.value >= 0x41 && scalar.value <= 0x5A) || (scalar.value >= 0x61 && scalar.value <= 0x7A)
    }

    private static func isASCIIDigit(_ character: Character) -> Bool {
        character.isASCII && ("0"..."9").contains(character)
    }

    /// Value of an ASCII digit. Callers have already checked `isASCIIDigit`.
    private static func digitValue(_ character: Character) -> Int {
        Int(character.asciiValue ?? 48) - 48
    }
}
