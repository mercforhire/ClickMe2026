//
//  SignupHourlyRateViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupHourlyRateViewModel: ObservableObject {

    // MARK: Form state
    /// User-facing string in **major units** (e.g. "80" = 80 dollars). The
    /// accumulator stores minor units (cents) — conversion happens at the
    /// boundary in `hydrate`/`commit`.
    @Published var rateString: String
    @Published var currency: String

    // MARK: Accumulator (optional — nil in previews)

    private let accumulator: SignupAccumulator?

    /// Assumes 2 fractional digits (USD/EUR/GBP/…). Matches
    /// `TopicEditorViewModel`'s `rateMajor * 100`. Currencies with 0
    /// fractional digits (JPY, KRW) will need a per-currency lookup once
    /// the picker exposes them — flagged, not fixed here.
    private static let minorUnitsPerMajor = 100

    // MARK: Init

    init(
        rateString: String = "0",
        currency: String = "USD",
        accumulator: SignupAccumulator? = nil
    ) {
        self.accumulator = accumulator
        // Hydrate from accumulator if present, else fall back to the
        // passed-in values (used by previews).
        if let accumulator {
            if let minor = accumulator.hourlyRateAmount {
                self.rateString = String(minor / Self.minorUnitsPerMajor)
            } else {
                self.rateString = rateString
            }
            self.currency = accumulator.hourlyRateCurrency
        } else {
            self.rateString = rateString
            self.currency = currency
        }
    }

    // MARK: Derived

    /// Major-unit integer typed by the user (e.g. `80` for `$80`).
    var rateValue: Int {
        Int(rateString) ?? 0
    }

    /// Minor-unit value shipped to the backend (`amount` field on
    /// `SetupExpertProfileRequest.hourlyRate`).
    private var minorUnitAmount: Int {
        rateValue * Self.minorUnitsPerMajor
    }

    // MARK: Mutations

    /// Strips non-digits, drops leading zeros, and falls back to "0" if empty.
    /// Mirrors the sanitized value onto the accumulator so the "Publish"
    /// step doesn't have to re-read.
    func sanitizeRateString() {
        let digits = rateString.filter(\.isNumber)
        let normalized = digits.isEmpty ? "0" : String(Int(digits) ?? 0)
        if normalized != rateString { rateString = normalized }
        accumulator?.hourlyRateAmount = minorUnitAmount
    }

    func selectCurrency(_ code: String) {
        currency = code
        accumulator?.hourlyRateCurrency = code
    }

    /// Commit both fields to the accumulator. Called from the "Next"
    /// button so a user who never edits the sanitizer still writes their
    /// initial defaults through.
    func commitToAccumulator() {
        accumulator?.hourlyRateAmount = minorUnitAmount
        accumulator?.hourlyRateCurrency = currency
    }
}
