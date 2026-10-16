//
//  ClientBookingItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Single booking row returned by `GET /client/bookings`.
///
/// x-discrepancy #13: `expert.expertise_rim_color` from the API reference spec
/// is NOT present. `start_time`/`end_time` are full ISO 8601 UTC datetime strings
/// (spec specified time-only AM/PM + separate date).
struct ClientBookingItem: Decodable {
    struct Expert: Decodable {
        let id: UUID
        let fullName: String?
        let avatarUrl: String?
    }

    let bookingId: UUID
    let expert: Expert
    let topic: String?
    let startTime: Date
    let endTime: Date
    let meetingType: MeetingType
    /// Raw DB booking status enum value (e.g. `confirmed`, `pending_approval`).
    let status: String
    /// Truncated preview (~140 chars) of the caller's private note on
    /// this booking. `nil` when no note exists. Full text lives at
    /// `GET /(client/)bookings/:id/note`.
    let privateNotePreview: String?
    /// Present when `status == pending_reschedule` — carries the
    /// proposed new start plus who initiated it. Enough for a card
    /// badge; the full proposal (note, timezone, end, created_at)
    /// lives on the detail response.
    let reschedule: ReschedulePreview?
}
