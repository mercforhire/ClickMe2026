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
    @Published var rateString: String
    @Published var currency: String

    // MARK: Accumulator (optional — nil in previews)

    private let accumulator: SignupAccumulator?

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
            if let amount = accumulator.hourlyRateAmount {
                self.rateString = String(amount)
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

    var rateValue: Int {
        Int(rateString) ?? 0
    }

    // MARK: Mutations

    /// Strips non-digits, drops leading zeros, and falls back to "0" if empty.
    /// Mirrors the sanitized value onto the accumulator so the "Publish"
    /// step doesn't have to re-read.
    func sanitizeRateString() {
        let digits = rateString.filter(\.isNumber)
        let normalized = digits.isEmpty ? "0" : String(Int(digits) ?? 0)
        if normalized != rateString { rateString = normalized }
        accumulator?.hourlyRateAmount = Int(rateString)
    }

    func selectCurrency(_ code: String) {
        currency = code
        accumulator?.hourlyRateCurrency = code
    }

    /// Commit both fields to the accumulator. Called from the "Next"
    /// button so a user who never edits the sanitizer still writes their
    /// initial defaults through.
    func commitToAccumulator() {
        accumulator?.hourlyRateAmount = Int(rateString)
        accumulator?.hourlyRateCurrency = currency
    }
}
