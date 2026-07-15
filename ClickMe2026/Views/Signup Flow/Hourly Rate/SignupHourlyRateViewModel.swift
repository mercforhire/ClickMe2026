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

    // MARK: Data
    let currencies: [String]

    init(
        rateString: String = "0",
        currency: String = "USD",
        currencies: [String] = ["USD", "CAD", "EUR", "GBP", "AUD", "JPY", "CHF", "SGD", "INR"]
    ) {
        self.rateString = rateString
        self.currency = currency
        self.currencies = currencies
    }

    // MARK: Derived

    var rateValue: Int {
        Int(rateString) ?? 0
    }

    // MARK: Mutations

    /// Strips non-digits, drops leading zeros, and falls back to "0" if empty.
    func sanitizeRateString() {
        let digits = rateString.filter(\.isNumber)
        let normalized = digits.isEmpty ? "0" : String(Int(digits) ?? 0)
        if normalized != rateString { rateString = normalized }
    }

    func selectCurrency(_ code: String) {
        currency = code
    }
}
