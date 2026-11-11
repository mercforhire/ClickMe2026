//
//  UpcomingActionPolicy.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which actions the client Upcoming Booking details screen offers.
///
/// The Cancel rule mirrors the backend, so the button is never shown when the
/// server would refuse it. In `clientBooking.controller.js`, client cancel
/// accepts only the statuses in `cancellableStatuses` (`confirmed`,
/// `pending_approval`, `pending_reschedule`) and rejects a cancel at or after
/// `end_time` with 409 `SESSION_ALREADY_ENDED` (BACK-12). The Reschedule rule
/// mirrors `canReschedule` in `src/utils/reschedule.js`. This is a display
/// gate only; the server keeps the final say.
enum UpcomingActionPolicy {

    /// The statuses `POST /client/bookings/:id/cancel` accepts.
    static let cancellableStatuses: Set<BookingStatus> = [.confirmed, .pendingApproval, .pendingReschedule]

    /// Reschedulable whatever the time (`NO_TIME_GATE_STATUSES` in `reschedule.js`).
    static let reschedulableStatuses: Set<BookingStatus> = [.confirmed, .pendingApproval, .pendingReschedule]

    /// Reschedulable only while the original scheduled end is still ahead
    /// (`TIME_GATED_STATUSES`). `missed` is deliberately absent.
    static let timeGatedReschedulableStatuses: Set<BookingStatus> = [.completed, .inProgress]

    /// True when Cancel should be offered at `now`.
    ///
    /// - Parameters:
    ///   - status: The booking's decoded status.
    ///   - end: The scheduled end. `nil` (not loaded yet) hides Cancel.
    ///   - now: The moment to evaluate; callers pass the timeline's date.
    static func canShowCancel(status: BookingStatus, end: Date?, now: Date) -> Bool {
        guard cancellableStatuses.contains(status), let end else { return false }
        return end > now
    }

    /// True when Reschedule should be offered at `now`.
    ///
    /// - Parameters:
    ///   - status: The booking's decoded status.
    ///   - end: The scheduled end. `nil` (not loaded yet) hides Reschedule for the
    ///     time-gated statuses, which need it.
    ///   - now: The moment to evaluate; callers pass the timeline's date.
    static func canShowReschedule(status: BookingStatus, end: Date?, now: Date) -> Bool {
        if reschedulableStatuses.contains(status) { return true }
        guard timeGatedReschedulableStatuses.contains(status), let end else { return false }
        return now < end
    }
}
