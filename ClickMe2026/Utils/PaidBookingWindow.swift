//
//  PaidBookingWindow.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// How far ahead a paid session can start (BOOK-14).
///
/// Mirrors the backend's `LONG_LEAD_THRESHOLD_MS` (`src/utils/reschedule.js`):
/// the server refuses a paid start that is strictly more than 6 days ahead, so
/// a start at exactly 6 days is allowed. Free topics have no limit. The picker
/// uses this to hide what the server would refuse; the server stays the
/// backstop with a 422 (`LONG_LEAD_NOT_AVAILABLE`, `RESCHEDULE_TOO_FAR_AHEAD`).
///
/// The helper never reads the clock. Callers pass `now` and must read it again
/// at each evaluation, so a screen left open does not keep a stale limit.
nonisolated enum PaidBookingWindow {

    /// Longest lead, in seconds, a paid session may have.
    static let maxLead: TimeInterval = 6 * 24 * 3600

    /// The latest allowed start, or nil when there is no limit (a free topic).
    static func latestStart(isPaid: Bool, now: Date) -> Date? {
        isPaid ? now.addingTimeInterval(maxLead) : nil
    }

    /// Whether `start` is inside the limit. The limit itself is allowed; a nil
    /// limit allows everything.
    static func allows(_ start: Date, latestStart: Date?) -> Bool {
        guard let latestStart else { return true }
        return start <= latestStart
    }

    /// Whether every moment of `day` is past the limit, so the whole day can
    /// be hidden. False for a nil limit.
    static func isDayBeyond(_ day: Date, latestStart: Date?, calendar: Calendar) -> Bool {
        guard let latestStart else { return false }
        return calendar.startOfDay(for: day) > latestStart
    }

    /// Whether a booking counts as paid for the reschedule limit.
    ///
    /// A booking is paid when its `payment_status` is anything but `none`, or
    /// when its topic is not free. The second test matters for a long-lead
    /// paid booking: it has no PaymentIntent yet (it is charged at T-24h), so
    /// its `payment_status` still reads `none` while the server applies the
    /// 6-day limit to it. Over-capping is safe; the server stays the backstop.
    /// Mirrors Android's `RescheduleRules.isPaid`.
    static func isPaidReschedule(paymentStatus: String, topicIsFree: Bool) -> Bool {
        paymentStatus != "none" || !topicIsFree
    }
}
