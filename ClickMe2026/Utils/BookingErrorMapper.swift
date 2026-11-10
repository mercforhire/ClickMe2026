//
//  BookingErrorMapper.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// One `ErrorCode` to copy table for booking and reschedule errors, shared by
/// the free and the paid Make a Booking paths (PAY-05) and the reschedule
/// screens (BOOK-14).
///
/// Branch on `ErrorCode`, never on the message text. The paid booking copy is
/// the base; context-specific copy (for example outside the authorization
/// window) stays in the view model that owns that context. A code with no
/// entry here returns the caller's fallback, which is normally the server's
/// own message (`Error.userMessage`).
enum BookingErrorMapper {

    /// Shown for both long-lead codes. The server refuses a paid start that
    /// is strictly more than 6 days ahead.
    static let longLeadMessage = "Paid sessions can be booked up to 6 days ahead. Please choose an earlier time."

    /// Shown when a paid booking is rescheduled past the same limit.
    static let rescheduleTooFarAheadMessage =
        "Paid sessions can be rescheduled up to 6 days ahead. Please choose a time within the next 6 days."

    /// The `ErrorCode` carried by a `NetworkError.httpError` body, or nil for
    /// any other error, an undecodable body, or a code the app does not know.
    static func code(for error: Error) -> ErrorCode? {
        guard case let NetworkError.httpError(_, data) = error,
              let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        else { return nil }
        return response.code
    }

    /// The user-facing text for `code`, or `fallback` when there is no code or
    /// the table has no entry for it.
    static func message(for code: ErrorCode?, fallback: String) -> String {
        switch code {
        case .slotUnavailable:
            return "That time slot was just taken. Please pick another."
        case .meetingLinkUnavailable:
            return "The expert hasn't set up their Skype/Zoom link yet. Please choose in-app voice instead."
        case .expertNotBookable:
            return "This expert isn't accepting bookings right now."
        case .invalidPaymentMethod:
            return "This payment method can't be used for this booking. Please choose another card."
        case .directChargeDisabled:
            return "Payments are temporarily unavailable. Please try again in a few minutes."
        case .paymentFailed:
            return "Your card was declined. Please try another card."
        case .duplicateBooking:
            return "A booking for this session already exists."
        case .amountBelowMinimum:
            return "The session total is below the minimum charge amount."
        case .invalidPromo:
            return "That promo code isn't valid."
        case .cannotBookSelf:
            return "You can't book yourself."
        case .bookingAttemptConflict:
            return "Please try booking again."
        case .longLeadRequiresSavedCard, .longLeadNotAvailable:
            return longLeadMessage
        case .rescheduleTooFarAhead:
            return rescheduleTooFarAheadMessage
        default:
            return fallback
        }
    }

    /// Convenience for a caught error: the mapped copy for its code, else the
    /// server message.
    static func message(for error: Error) -> String {
        message(for: code(for: error), fallback: error.userMessage)
    }
}
