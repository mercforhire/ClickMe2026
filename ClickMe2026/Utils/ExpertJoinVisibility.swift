//
//  ExpertJoinVisibility.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// When the expert Booking Summary renders Join Session, and when it is
/// enabled (CALL-10).
///
/// `JoinWindow.showsJoinButton(status:)` is a list-card rule and returns true
/// for cancelled, declined, missed and expired bookings, so it is not used
/// here. The summary shows Join only where it can matter:
///
/// - `confirmed`, `in_progress` and `pending_reschedule` always show it. A
///   `pending_reschedule` booking shows it disabled, as the cards do
///   (Phase 2 D-07, D-12 as amended).
/// - `completed` shows it only while `JoinWindow.isOpen` is true, i.e. inside
///   the server-approved reconnect tier.
/// - Every other status hides it.
///
/// Enabling is `JoinWindow.isOpen` unchanged. A display gate only: the server
/// keeps the final say on `POST /bookings/:id/join`. The helper never reads
/// the clock; callers pass `now`.
enum ExpertJoinVisibility {

    /// Statuses that always render the button, enabled or not.
    static let alwaysShownStatuses: Set<BookingStatus> = [.confirmed, .inProgress, .pendingReschedule]

    /// True when the summary should render Join Session at `now`.
    ///
    /// - Parameters:
    ///   - status: The booking's wire status.
    ///   - start: Scheduled start (UTC).
    ///   - end: Scheduled end (UTC).
    ///   - now: The moment to evaluate; callers pass the timeline date.
    ///   - serverCanJoin: The detail payload's `actions.canJoin`.
    static func shows(
        status: BookingStatus,
        start: Date,
        end: Date,
        now: Date,
        serverCanJoin: Bool?
    ) -> Bool {
        if alwaysShownStatuses.contains(status) { return true }
        return JoinWindow.isOpen(
            status: status,
            start: start,
            end: end,
            now: now,
            serverCanJoin: serverCanJoin
        )
    }

    /// True when the rendered button is tappable. Equals `JoinWindow.isOpen`.
    static func isEnabled(
        status: BookingStatus,
        start: Date,
        end: Date,
        now: Date,
        serverCanJoin: Bool?
    ) -> Bool {
        JoinWindow.isOpen(
            status: status,
            start: start,
            end: end,
            now: now,
            serverCanJoin: serverCanJoin
        )
    }
}
