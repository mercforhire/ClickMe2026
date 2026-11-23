//
//  BookingSummaryPrice.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-22.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// What the Booking Summary price row shows. It mirrors Android's
/// `PriceDisplay` and the price label on Upcoming Booking details, so the same
/// booking reads the same on every screen and platform. The row is shown for
/// every loaded booking, including a free one (G-03-1-ITEM14).
nonisolated enum BookingSummaryPrice: Equatable {
    /// The server says the topic is free.
    case free
    /// A paid topic. Holds the amount already formatted, for example `"CA$45.50"`.
    case paid(String)
    /// A paid topic whose detail is missing the amount or the currency.
    case unknown

    /// Builds the row from the topic fields of the booking detail.
    ///
    /// An explicit `isFree` of true wins even when a price is also present
    /// (Android `PriceDisplay.of`). Otherwise both an amount and a currency are
    /// needed; with either missing no amount is invented.
    ///
    /// - Parameters:
    ///   - isFree: `topic.is_free` from the server.
    ///   - amount: `topic.price.amount` in minor units (cents). `Money` formats it
    ///     with integer math, so cents are kept for prices like 45.50.
    ///   - currency: `topic.price.currency`, an ISO code such as `"CAD"`.
    static func make(isFree: Bool, amount: Int?, currency: String?) -> BookingSummaryPrice {
        if isFree { return .free }
        guard let amount, let currency else { return .unknown }
        return .paid(Money.format(minorUnits: amount, currency: currency))
    }

    /// The value shown beside the label. Free is a localizable literal so Xcode
    /// extracts it into `Localizable.xcstrings`. The dash is a symbol, not a
    /// word, so it is not translated.
    var text: String {
        switch self {
        case .free:
            String(localized: "Free", comment: "Booking Summary price row value for a free session.")
        case let .paid(amount):
            amount
        case .unknown:
            "\u{2014}"
        }
    }

    /// The caption before the value. "Session fee" appears only when the server
    /// says the topic is free (user decision 2026-11-22), as on Android's
    /// `booking_summary_session_fee`. Every other row keeps "PAID", as before
    /// G-03-1-ITEM14.
    var label: String {
        switch self {
        case .free:
            String(localized: "Session fee", comment: "Booking Summary price row label for a free session.")
        case .paid, .unknown:
            String(localized: "PAID")
        }
    }
}
