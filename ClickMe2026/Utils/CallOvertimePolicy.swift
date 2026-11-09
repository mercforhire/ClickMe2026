//
//  CallOvertimePolicy.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Pure rules for how long a call may run past its scheduled end, when to
/// warn the user, and what duration to report to `POST /bookings/:id/end`.
///
/// The helper never reads the clock; callers pass `now`, which keeps every
/// boundary testable.
///
/// The cutoff must stay at 60 minutes. The server accepts `/end` with
/// `completed` on a cron-completed booking until end + 70 minutes, and the
/// Agora token expires at end + 70 minutes (`docs/ios/CALL-END-SEMANTICS.md`
/// in the backend repo). End + 60 is inside both, so raising it would let the
/// local rule outlive what the server will accept.
nonisolated enum CallOvertimePolicy {

    /// What the call screen should do on a timer tick.
    nonisolated enum Action: Equatable {
        /// Nothing to do: no scheduled end, or the call is not near the cutoff.
        case none
        /// Show the "This call will end in 5 minutes" notice.
        case warn
        /// End the call through the normal end path.
        case end
    }

    /// Seconds past the scheduled end at which the app ends the call.
    static let cutoff: TimeInterval = 60 * 60

    /// Seconds before the cutoff at which the notice appears.
    static let warningLead: TimeInterval = 5 * 60

    /// Decides what to do for the given scheduled end and current time.
    ///
    /// - Parameters:
    ///   - scheduledEnd: The booking's scheduled end, or `nil` when unknown,
    ///     in which case the call is never ended or warned about locally.
    ///   - now: The current time.
    static func action(scheduledEnd: Date?, now: Date) -> Action {
        guard let scheduledEnd else { return .none }
        let overtime = now.timeIntervalSince(scheduledEnd)
        if overtime >= cutoff { return .end }
        if overtime >= cutoff - warningLead { return .warn }
        return .none
    }
}
