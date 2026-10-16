//
//  BookingRequestItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Single booking request row returned by `GET /expert/booking-requests`.
///
/// x-discrepancy #15: `time_slot` contains full ISO 8601 UTC datetime strings
/// for `start_time` and `end_time` — the spec specified time-only sub-fields
/// plus separate `date` and `timezone` fields.
struct BookingRequestItem: Decodable {
    struct Client: Decodable {
        let id: UUID
        let fullName: String?
        let avatarUrl: String?
    }

    struct TimeSlotInterval: Decodable {
        let startTime: Date
        let endTime: Date
    }

    let requestId: UUID
    let client: Client
    let topic: String?
    /// **Legacy — gross.** What the client pays, in major currency units.
    /// Read `earningsBreakdown.netAmount` for the expert's take-home.
    let earnings: Double?
    let currency: String?
    let timeSlot: TimeSlotInterval
    let expiresAt: Date?
    /// `pending_approval` or `expired`.
    let status: String
    /// Post-commission breakdown — see `EarningsBreakdown`. Optional so
    /// pre-rollout cached list responses still decode.
    let earningsBreakdown: EarningsBreakdown?
}
