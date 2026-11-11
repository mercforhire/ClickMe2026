//
//  BookingStatusPill.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The text and tone of the status pill on Upcoming Booking details
/// (BOOK-09, 03-UI-SPEC "Status pill and booking ID").
///
/// The decoded `BookingStatus` case decides the pill, never the raw server
/// string (Phase 2 BOOK-18): a status this build does not know is `.unknown`,
/// which is always neutral, so it can never be shown as a confirmed booking.
/// `rawStatus` is read only to humanize that `.unknown` fallback.
///
/// `make(status:rawStatus:)` switches over every case with no `default`, so a
/// new `BookingStatus` case fails to compile until someone decides its pill.
struct BookingStatusPill: Equatable {

    enum Tone: Equatable {
        /// Brand green: a booking that is on track or done.
        case accent
        /// Orange: waiting on someone.
        case amber
        /// `onSurfaceVariant`: ended without a session, or not understood.
        case neutral
    }

    let text: String
    let tone: Tone

    /// - Parameters:
    ///   - status: The decoded status. Decides the text and tone of every known case.
    ///   - rawStatus: The server string. Used only when `status` is `.unknown`.
    static func make(status: BookingStatus, rawStatus: String) -> BookingStatusPill {
        switch status {
        case .confirmed:
            return BookingStatusPill(text: "Confirmed", tone: .accent)
        case .inProgress:
            return BookingStatusPill(text: "In progress", tone: .accent)
        case .completed:
            return BookingStatusPill(text: "Completed", tone: .accent)
        case .pendingApproval:
            return BookingStatusPill(text: "Pending approval", tone: .amber)
        case .pendingReschedule:
            return BookingStatusPill(text: "Pending reschedule", tone: .amber)
        case .cancelled, .declined:
            return BookingStatusPill(text: "Cancelled", tone: .neutral)
        case .missed, .expired:
            return BookingStatusPill(text: "Missed", tone: .neutral)
        case .rescheduled:
            return BookingStatusPill(text: "Rescheduled", tone: .neutral)
        case .unknown:
            return BookingStatusPill(text: humanize(rawStatus), tone: .neutral)
        }
    }

    /// Underscores to spaces, first letter upper-cased. An empty string reads "Unknown".
    private static func humanize(_ raw: String) -> String {
        let spaced = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
        guard let first = spaced.first else { return "Unknown" }
        return first.uppercased() + spaced.dropFirst()
    }
}
