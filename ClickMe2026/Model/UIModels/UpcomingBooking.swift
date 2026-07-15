//
//  UpcomingBooking.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Display model for a booking that hasn't happened yet. Backed by
/// `ClientBookingItem` with `BookingStatus` in the upcoming bucket
/// (`pendingApproval / confirmed / pendingReschedule / inProgress`).
struct UpcomingBooking: Identifiable, Hashable {
    /// Server booking UUID from `ClientBookingItem.bookingId`. Needed for
    /// future API mutations (reschedule/cancel).
    let id: UUID
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let imageURL: String
    /// Raw UTC start moment — the card uses this to decide whether the
    /// "Join Call" button is currently in range (within one hour of start).
    let startTime: Date

    /// True when `now` is within one hour of `startTime` — the join window.
    /// Symmetric so the button remains available for an hour after start
    /// too (bookings can run late).
    var isWithinJoinWindow: Bool {
        let delta = startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }
}
