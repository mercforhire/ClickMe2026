//
//  ChatBookingRowRoute.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which screen a tapped booking row inside a chat opens (D-18).
///
/// RED-phase stub: keeps the behaviour before D-18, which pushes the client
/// booking screens whatever the shell.
enum ChatBookingRowRoute {

    static func route(isTerminal: Bool, bookingId: UUID, hostsClientBookingFlows: Bool) -> HomeRoute {
        isTerminal ? .bookingSummary(bookingId: bookingId) : .upcomingBooking(bookingId: bookingId)
    }
}
