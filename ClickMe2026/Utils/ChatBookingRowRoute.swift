//
//  ChatBookingRowRoute.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which screen a tapped booking row inside a chat opens (D-18).
///
/// The client booking screens load `GET /client/bookings/:id`, which the
/// backend mounts behind `roleCheck('client')`, so an expert who opens them
/// gets a load error. The expert shell therefore opens
/// `ExpertBookingSummaryView` for active and finished bookings alike, as
/// Android does with `ExpertBookingSummaryKey`. The client shell keeps the
/// summary for finished bookings and the upcoming-booking screen for active ones.
///
/// The shell decides, not the viewer's role on the booking: a user who is the
/// client on a booking but taps its row in the expert shell (or the reverse)
/// still gets the shell's screen. See the dual-role todo in `.planning/todos`.
enum ChatBookingRowRoute {

    /// - Parameters:
    ///   - isTerminal: The booking event is in a finished state (declined,
    ///     cancelled, completed, expired).
    ///   - bookingId: The booking the row refers to.
    ///   - hostsClientBookingFlows: `\.hostsClientBookingFlows` from the
    ///     environment; false in the expert shell.
    static func route(isTerminal: Bool, bookingId: UUID, hostsClientBookingFlows: Bool) -> HomeRoute {
        guard hostsClientBookingFlows else { return .expertBookingSummary(bookingId: bookingId) }
        return isTerminal ? .bookingSummary(bookingId: bookingId) : .upcomingBooking(bookingId: bookingId)
    }
}
