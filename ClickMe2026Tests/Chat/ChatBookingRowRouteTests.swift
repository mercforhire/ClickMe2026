//
//  ChatBookingRowRouteTests.swift
//  ClickMe2026Tests
//
//  D-18: a tapped booking row inside a chat opens the expert Booking Summary in
//  the expert shell, active or finished, and keeps the client screens in the
//  client shell (summary when finished, upcoming booking when active). Pure:
//  no network and no view.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat booking row route")
@MainActor
struct ChatBookingRowRouteTests {

    private static let bookingId = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!

    @Test("expert shell, finished booking opens the expert summary")
    func expertShellTerminal() {
        let route = ChatBookingRowRoute.route(
            isTerminal: true, bookingId: Self.bookingId, hostsClientBookingFlows: false
        )
        #expect(route == .expertBookingSummary(bookingId: Self.bookingId))
    }

    @Test("expert shell, active booking opens the expert summary")
    func expertShellActive() {
        let route = ChatBookingRowRoute.route(
            isTerminal: false, bookingId: Self.bookingId, hostsClientBookingFlows: false
        )
        #expect(route == .expertBookingSummary(bookingId: Self.bookingId))
    }

    @Test("client shell, finished booking keeps the client summary")
    func clientShellTerminal() {
        let route = ChatBookingRowRoute.route(
            isTerminal: true, bookingId: Self.bookingId, hostsClientBookingFlows: true
        )
        #expect(route == .bookingSummary(bookingId: Self.bookingId))
    }

    @Test("client shell, active booking keeps the upcoming booking screen")
    func clientShellActive() {
        let route = ChatBookingRowRoute.route(
            isTerminal: false, bookingId: Self.bookingId, hostsClientBookingFlows: true
        )
        #expect(route == .upcomingBooking(bookingId: Self.bookingId))
    }
}
