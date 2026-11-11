//
//  CancelBookingData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// `data` of `POST /client/bookings/:id/cancel` (openapi `cancelClientBooking`).
///
/// `refundAmount` is in major units (for example `45.0` for CA$45.00), so it
/// goes through `Money.format(major:currency:)`. The backend returns 0 for a
/// released hold, a charge cancelled within 24 hours, a free booking, and a
/// void or refund that failed and is being retried (flagged `refund_failed`),
/// so 0 never means "no refund" on its own. The idempotent already-cancelled
/// 200 also carries 0.
struct CancelBookingData: Decodable {
    let refundAmount: Double
    let currency: String
}
