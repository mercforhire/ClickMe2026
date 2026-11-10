//
//  BookingStatus.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Canonical booking status enum. UPCOMING: `pendingApproval`, `confirmed`,
/// `pendingReschedule`, `inProgress`. PAST: `completed`, `cancelled`,
/// `declined`, `missed`, `expired`. SOCKET-ONLY / FALLBACK: `rescheduled`,
/// `unknown`.
///
/// Decoding never fails on a string: a value this build does not know
/// becomes `.unknown`, so one new server status can't drop a whole
/// `booking.update` event or fail a list response. A missing or
/// non-string status still throws (the contract says it is always a
/// string).
enum BookingStatus: String, Decodable {
    case pendingApproval    = "pending_approval"
    case confirmed
    case pendingReschedule  = "pending_reschedule"
    case inProgress         = "in_progress"
    case completed
    case cancelled
    case declined
    case missed
    case expired
    /// Socket-only value (`docs/SOCKET-CONTRACT.md`). The database never
    /// stores it (backend `src/utils/bookingStatusSets.js`), so it only
    /// arrives on a realtime `booking.update`.
    case rescheduled
    /// Any status string this build does not know yet.
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = BookingStatus(rawValue: raw) ?? .unknown
    }
}
