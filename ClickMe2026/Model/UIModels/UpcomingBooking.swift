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
    /// Server UUID of the expert on this booking. Used to look up (or
    /// create) the chat thread when the row's Message button is tapped.
    let expertId: UUID
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let imageURL: String
    /// Raw UTC start moment — the card uses this to decide whether the
    /// "Join Call" button is currently in range (within one hour of start).
    let startTime: Date
    /// Raw UTC end moment — plumbed into `MeetingCallView` so the call
    /// screen can render the scheduled time range and drive the
    /// "5 min remaining" warning + soft "time is up" banner.
    let endTime: Date
    /// Raw booking status from `ClientBookingItem.status`. Used to gate
    /// the Join Call button (hidden when `pendingApproval`) and to
    /// surface a "Waiting for expert to accept" affordance instead.
    let status: BookingStatus

    /// True when `now` is within one hour of `startTime` AND the booking
    /// has been accepted by the expert. Symmetric window so the button
    /// remains available for an hour after start too (bookings can run
    /// late). `pendingApproval` bookings never open the join window —
    /// the expert hasn't accepted yet, there's no channel to join.
    var isWithinJoinWindow: Bool {
        guard status != .pendingApproval else { return false }
        let delta = startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }

    /// True when the booking is still awaiting the expert's decision.
    /// Drives the "Waiting for expert to accept" banner on both the
    /// bookings list card and the booking-detail view.
    var isPendingExpertApproval: Bool {
        status == .pendingApproval
    }
}
