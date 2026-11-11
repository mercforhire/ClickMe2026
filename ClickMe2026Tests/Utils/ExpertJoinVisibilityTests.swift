//
//  ExpertJoinVisibilityTests.swift
//  ClickMe2026Tests
//
//  CALL-10: the expert Booking Summary shows Join Session for confirmed,
//  in_progress and pending_reschedule bookings, and for a completed booking
//  only inside the reconnect window. It is enabled exactly when
//  `JoinWindow.isOpen`.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Expert join visibility")
struct ExpertJoinVisibilityTests {

    private static let start = Date(timeIntervalSince1970: 1_800_000_000)
    private static let end = start.addingTimeInterval(1800)

    private nonisolated static let allStatuses: [BookingStatus] = [
        .pendingApproval, .confirmed, .pendingReschedule, .inProgress, .completed,
        .cancelled, .declined, .missed, .expired, .rescheduled, .unknown
    ]

    /// Far before the window, inside the first-join tier, inside the
    /// reconnect tier, and past the grace.
    private static let farBefore = start.addingTimeInterval(-JoinWindow.lead - 86_400)
    private static let inFirstJoin = start.addingTimeInterval(60)
    private static let inReconnect = start.addingTimeInterval(JoinWindow.minFirstJoinSpan + 600)
    private static let pastGrace = end.addingTimeInterval(JoinWindow.reconnectGrace + 600)

    private static func shows(_ status: BookingStatus, _ now: Date, canJoin: Bool? = true) -> Bool {
        ExpertJoinVisibility.shows(status: status, start: start, end: end, now: now, serverCanJoin: canJoin)
    }

    private static func enabled(_ status: BookingStatus, _ now: Date, canJoin: Bool? = true) -> Bool {
        ExpertJoinVisibility.isEnabled(status: status, start: start, end: end, now: now, serverCanJoin: canJoin)
    }

    @Test("confirmed, in_progress and pending_reschedule show at any time",
          arguments: [BookingStatus.confirmed, .inProgress, .pendingReschedule])
    func alwaysShown(status: BookingStatus) {
        for now in [Self.farBefore, Self.inFirstJoin, Self.inReconnect, Self.pastGrace] {
            #expect(Self.shows(status, now))
        }
    }

    @Test("completed shows only inside the reconnect window")
    func completedShowsInsideWindowOnly() {
        #expect(!Self.shows(.completed, Self.farBefore))
        #expect(Self.shows(.completed, Self.inFirstJoin))
        #expect(Self.shows(.completed, Self.inReconnect, canJoin: true))
        #expect(!Self.shows(.completed, Self.inReconnect, canJoin: false))
        #expect(!Self.shows(.completed, Self.pastGrace, canJoin: true))
    }

    @Test("statuses the server refuses never show, even inside the window",
          arguments: [BookingStatus.pendingApproval, .cancelled, .declined, .missed, .expired])
    func neverShown(status: BookingStatus) {
        for now in [Self.farBefore, Self.inFirstJoin, Self.inReconnect, Self.pastGrace] {
            #expect(!Self.shows(status, now))
        }
    }

    @Test("rescheduled and unknown never show", arguments: [BookingStatus.rescheduled, .unknown])
    func socketOnlyAndUnknownHidden(status: BookingStatus) {
        #expect(!Self.shows(status, Self.inFirstJoin))
    }

    @Test("isEnabled equals JoinWindow.isOpen for every status and moment")
    func enabledMatchesJoinWindow() {
        for status in Self.allStatuses {
            for now in [Self.farBefore, Self.inFirstJoin, Self.inReconnect, Self.pastGrace] {
                for canJoin in [true, false, nil] as [Bool?] {
                    let expected = JoinWindow.isOpen(
                        status: status, start: Self.start, end: Self.end, now: now, serverCanJoin: canJoin
                    )
                    #expect(Self.enabled(status, now, canJoin: canJoin) == expected)
                }
            }
        }
    }

    @Test("pending_reschedule is shown and disabled")
    func pendingRescheduleShownDisabled() {
        #expect(Self.shows(.pendingReschedule, Self.inFirstJoin))
        #expect(!Self.enabled(.pendingReschedule, Self.inFirstJoin))
    }

    @Test("confirmed outside the window is shown and disabled; inside it is enabled")
    func confirmedWindowEnablement() {
        #expect(Self.shows(.confirmed, Self.farBefore))
        #expect(!Self.enabled(.confirmed, Self.farBefore))
        #expect(Self.enabled(.confirmed, Self.inFirstJoin))
    }
}
