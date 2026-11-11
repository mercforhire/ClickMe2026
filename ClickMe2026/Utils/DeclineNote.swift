//
//  DeclineNote.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// What the client sees when an expert declined their booking request
/// (BACK-02, 03-UI-SPEC "Booking Summary"): a reason line mapped from
/// `decline_reason_code`, then the expert's own note.
///
/// The backend sends the code and text only when the status is `declined`
/// (backend openapi `ClientBookingDetail`). This type still checks the
/// status itself, so a stray value on another status is never shown.
struct DeclineNote: Equatable {

    /// The label for the code, or nil when the code is missing or not one
    /// this build knows. The raw code is never shown.
    let reasonLine: String?

    /// The expert's note, trimmed at both ends, or nil when blank. Plain
    /// text: render it as a `String`, never as Markdown.
    let text: String?

    /// The note to show, or nil when the card should not render.
    ///
    /// - Parameters:
    ///   - status: The raw booking status; only `"declined"` shows a note.
    ///   - code: `decline_reason_code` as sent by the server.
    ///   - text: `decline_reason_text` as sent by the server.
    static func make(status: String, code: String?, text: String?) -> DeclineNote? {
        guard status == BookingStatus.declined.rawValue else { return nil }
        let reasonLine = reasonLine(for: code)
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = (trimmed?.isEmpty == false) ? trimmed : nil
        guard reasonLine != nil || note != nil else { return nil }
        return DeclineNote(reasonLine: reasonLine, text: note)
    }

    /// The UI-SPEC wording for a decline code. `OUTSIDE_EXPERTISE` and
    /// `OUT_OF_SCOPE` share a line, as do `SCHEDULE_CONFLICT` and `CONFLICT`.
    /// Any other code, or nil, has no line.
    static func reasonLine(for code: String?) -> String? {
        switch code {
        case "UNAVAILABLE":                        return "Not available at that time"
        case "OUTSIDE_EXPERTISE", "OUT_OF_SCOPE":  return "Outside their expertise"
        case "SCHEDULE_CONFLICT", "CONFLICT":      return "Schedule conflict"
        case "PRICING":                            return "Pricing mismatch"
        case "OTHER":                              return "Other reason"
        default:                                   return nil
        }
    }
}
