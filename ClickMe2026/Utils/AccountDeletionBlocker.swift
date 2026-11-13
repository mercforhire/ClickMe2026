//
//  AccountDeletionBlocker.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Why a self-delete was refused with a 409, and what the blocker alert says
/// and offers (SET-06, D-10).
///
/// The backend's `assertNoBlockingBookings` (account.controller.js) returns
/// one of three codes from both `POST /user/account/delete-request` and
/// `DELETE /user/account`. The text here is iOS-owned: server messages are not
/// shown for these codes, and the text names no booking, person or amount.
/// Branch on `ErrorCode`, never on the message.
enum AccountDeletionBlocker: Equatable {
    /// Upcoming bookings where the user is the expert.
    case expertUpcoming
    /// Upcoming sessions the user booked as a client (confirmed or
    /// pending_reschedule; pending_approval does not block).
    case clientUpcoming
    /// A session is live or about to start, on either side.
    case sessionInProgress

    static let title = "You can't delete your account yet"

    /// Title Case per UI-SPEC CP1, matching the shipped Request Sent button.
    static let bookingsActionLabel = "View My Bookings"

    /// - Parameter code: The 409 body's code. Any code other than the three
    ///   blocker codes, and nil, is not a blocker.
    init?(code: ErrorCode?) {
        switch code {
        case .expertHasUpcomingBookings: self = .expertUpcoming
        case .clientHasUpcomingBookings: self = .clientUpcoming
        case .sessionInProgress: self = .sessionInProgress
        default: return nil
        }
    }

    /// Whether the alert offers "View My Bookings". The bookings list that
    /// holds the blocking bookings is the one for the blocker's side, so the
    /// action is only useful when the active mode matches it. A session in
    /// progress is reachable from either mode.
    func offersBookingsAction(in mode: AppMode) -> Bool {
        switch self {
        case .expertUpcoming: mode == .expert
        case .clientUpcoming: mode == .client
        case .sessionInProgress: true
        }
    }

    /// The alert message. In the wrong mode it names the mode to switch to.
    func message(in mode: AppMode) -> String {
        switch (self, mode) {
        case (.expertUpcoming, .expert):
            "You have upcoming bookings as an expert. Cancel or finish them, then try again."
        case (.expertUpcoming, .client):
            "You have upcoming bookings as an expert. Switch to Expert mode to cancel or finish them, then try again."
        case (.clientUpcoming, .client):
            "You have upcoming sessions booked. Cancel them, then try again."
        case (.clientUpcoming, .expert):
            "You have upcoming sessions booked as a client. Switch to Client mode to cancel them, then try again."
        case (.sessionInProgress, _):
            "A session is in progress or starts within 15 minutes. Wait until it ends, then try again."
        }
    }
}
