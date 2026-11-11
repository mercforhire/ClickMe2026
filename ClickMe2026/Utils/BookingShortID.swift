//
//  BookingShortID.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The short booking ID a client sees, for example `#7F3C9A2B` (BOOK-20,
/// 03-UI-SPEC D1): `#` plus the first 8 characters of the booking id,
/// upper-cased.
///
/// This is the same rule as Android `shortBookingId`
/// (`upcomingbooking/UpcomingBookingUiState.kt`), so support can match an ID
/// across platforms. Used by Upcoming Booking details and, in plan 03-07,
/// Booking Summary.
enum BookingShortID {

    /// How many characters of the id follow the `#`.
    static let length = 8

    /// `#` plus the first `length` characters of `id`, upper-cased.
    static func short(_ id: UUID) -> String {
        "#" + id.uuidString.prefix(length).uppercased()
    }

    /// `ID: ` plus `short(_:)`, the line shown under or beside the status.
    static func label(_ id: UUID) -> String {
        "ID: " + short(id)
    }
}
