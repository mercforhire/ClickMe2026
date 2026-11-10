//
//  JoinWindow.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The one rule for when a booking's Join button is offered (CALL-02).
///
/// It equals the backend's `evaluateJoinWindow` (`src/services/agora.js`) and
/// `JOINABLE_BOOKING_STATUSES` (`src/utils/bookingStatusSets.js`):
///
/// - The status must be `confirmed`, `in_progress` or `completed`. A
///   `pending_reschedule` booking is deliberately not joinable.
/// - Join opens `lead` (60 minutes) before the scheduled start.
/// - A first join stays possible until the later of the scheduled end and
///   `minFirstJoinSpan` (60 minutes) after the start, so the second half of a
///   session longer than an hour can still be joined.
/// - After that edge, a reconnect is allowed until `reconnectGrace`
///   (60 minutes) after the scheduled end, but only when the server says so
///   (`can_join == true`). Without the server flag the window is closed.
///
/// Every edge is inclusive. The result is a display gate, never an
/// authorization: the server keeps the final say on `POST /bookings/:id/join`.
/// The helper never reads the clock; callers pass `now`.
enum JoinWindow {

    /// How long before the scheduled start Join opens.
    static let lead: TimeInterval = 3600
    /// A first join is possible for at least this long after the scheduled start.
    static let minFirstJoinSpan: TimeInterval = 3600
    /// How long after the scheduled end a server-approved reconnect stays possible.
    static let reconnectGrace: TimeInterval = 3600
    /// Statuses the backend lets through `POST /join`.
    static let joinableStatuses: Set<BookingStatus> = [.confirmed, .inProgress, .completed]

    /// True when the status is one the server accepts a join for.
    static func isJoinableStatus(_ status: BookingStatus) -> Bool {
        joinableStatuses.contains(status)
    }

    /// Whether a card renders a Join button at all; `isOpen` then decides
    /// whether it is enabled.
    ///
    /// Android parity (user decision 2026-11-10, which supersedes the hide in
    /// D-12): every card shows Join, dimmed and disabled while `isOpen` is
    /// false, so a `pending_reschedule` booking shows a disabled Join rather
    /// than none. The one exception is a booking still awaiting the expert's
    /// approval, where the client card shows its "Waiting for expert to
    /// accept" banner in place of the button, as Android's My Bookings card
    /// does. Presentation only: the joining rule above is unchanged.
    static func showsJoinButton(status: BookingStatus) -> Bool {
        status != .pendingApproval
    }

    /// True when Join should be offered for this booking at `now`.
    ///
    /// - Parameters:
    ///   - status: The booking's wire status.
    ///   - start: Scheduled start (UTC).
    ///   - end: Scheduled end (UTC).
    ///   - now: The moment to evaluate; callers pass `Date()`.
    ///   - serverCanJoin: The booking's `can_join` when the payload has one.
    ///     `nil` for payloads that do not carry it (the client list); `nil` and
    ///     `false` both close the reconnect tier.
    static func isOpen(
        status: BookingStatus,
        start: Date,
        end: Date,
        now: Date,
        serverCanJoin: Bool?
    ) -> Bool {
        guard isJoinableStatus(status) else { return false }
        guard now >= start.addingTimeInterval(-lead) else { return false }

        let firstJoinDeadline = max(end, start.addingTimeInterval(minFirstJoinSpan))
        if now <= firstJoinDeadline { return true }

        return serverCanJoin == true && now <= end.addingTimeInterval(reconnectGrace)
    }
}
