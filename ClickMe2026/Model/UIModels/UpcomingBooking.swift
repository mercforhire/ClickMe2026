//
//  UpcomingBooking.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
    /// Whether this booking runs on Agora voice (`.inAppVoice`) or an
    /// external Skype/Zoom link (`.skypeZoom`). Plumbed into the call
    /// container as an initial hint so the correct call surface
    /// (in-app voice UI vs. external-link UI) renders immediately when
    /// Join Call is tapped, before `POST /join` returns.
    let meetingType: MeetingType
    /// Truncated preview of the client's private note on this booking,
    /// surfaced from `ClientBookingItem.private_note_preview`. `nil` when
    /// no note has been written. Drives the note footer on the card and
    /// the pencil-vs-plus glyph on the Private Note button.
    let privateNotePreview: String?
    /// Slim reschedule payload — set when `status == .pendingReschedule`.
    /// Drives the amber "Reschedule requested / proposed" badge on the
    /// card so the user notices without drilling into the summary.
    let reschedule: ReschedulePreview?

    /// True when `now` is within one hour of `startTime` AND the booking
    /// has been accepted by the expert. Symmetric window so the button
    /// remains available for an hour after start too (bookings can run
    /// late). `pendingApproval` bookings never open the join window —
    /// the expert hasn't accepted yet, there's no channel to join.
    ///
    /// Completed sessions whose scheduled end is still in the future are
    /// re-joinable: someone may have hung up early and want to resume.
    /// The client shows the button; the server has the final say on
    /// whether `POST /join` succeeds.
    var isWithinJoinWindow: Bool {
        if status == .pendingApproval { return false }
        if status == .completed { return endTime > Date() }
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
