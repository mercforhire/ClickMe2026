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
/// `end_time` with 409 `SESSION_ALREADY_ENDED` (BACK-12). This is a display
/// gate only; the server keeps the final say.
enum UpcomingActionPolicy {

    /// The statuses `POST /client/bookings/:id/cancel` accepts.
    static let cancellableStatuses: Set<BookingStatus> = [.confirmed, .pendingApproval, .pendingReschedule]

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
}
