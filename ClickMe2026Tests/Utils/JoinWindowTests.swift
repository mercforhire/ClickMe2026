//
//  JoinWindowTests.swift
//  ClickMe2026Tests
//
//  CALL-02: Join opens 60 minutes before start and stays open until the later
//  of the scheduled end and start + 60 minutes. After that, only a booking the
//  server marks `can_join` stays open, until end + 60 minutes. Mirrors the
//  backend's `evaluateJoinWindow`.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("JoinWindow")
struct JoinWindowTests {

    private static let start = Date(timeIntervalSince1970: 1_800_000_000)
    private static let minute: TimeInterval = 60

    private static func end(afterMinutes minutes: Double) -> Date {
        start.addingTimeInterval(minutes * minute)
    }

    private static func isOpen(
        _ status: BookingStatus = .confirmed,
        sessionMinutes: Double,
        offset: TimeInterval,
        relativeTo anchor: Anchor = .start,
        serverCanJoin: Bool? = nil
    ) -> Bool {
        let end = end(afterMinutes: sessionMinutes)
        let now = (anchor == .start ? start : end).addingTimeInterval(offset)
        return JoinWindow.isOpen(
            status: status,
            start: start,
            end: end,
            now: now,
            serverCanJoin: serverCanJoin
        )
    }

    enum Anchor: Sendable { case start, end }

    // MARK: - 30-minute session

    /// (seconds from start, expected open)
    private nonisolated static let shortSession: [(offset: TimeInterval, open: Bool)] = [
        (-3601, false),   // start - 60:01
        (-3600, true),    // start - 60:00, inclusive
        (0, true),        // start
        (1800, true),     // end
        (3599, true),
        (3600, true),     // start + 60:00 = max(end, start + 60), inclusive
        (3601, false)     // start + 60:01, no server flag
    ]

    @Test("30-minute session, confirmed, no server flag", arguments: shortSession)
    func shortSessionEdges(row: (offset: TimeInterval, open: Bool)) {
        #expect(Self.isOpen(sessionMinutes: 30, offset: row.offset) == row.open)
    }

    // MARK: - 2-hour session

    @Test("2-hour session: second half is joinable")
    func secondHalfOfLongSession() {
        #expect(Self.isOpen(sessionMinutes: 120, offset: 90 * Self.minute))
        #expect(Self.isOpen(sessionMinutes: 120, offset: 0, relativeTo: .end))
    }

    @Test("2-hour session: one second past the end closes without the server flag")
    func pastEndWithoutFlag() {
        #expect(!Self.isOpen(sessionMinutes: 120, offset: 1, relativeTo: .end))
        #expect(!Self.isOpen(sessionMinutes: 120, offset: 1, relativeTo: .end, serverCanJoin: nil))
        #expect(!Self.isOpen(sessionMinutes: 120, offset: 1, relativeTo: .end, serverCanJoin: false))
    }

    /// (seconds from end, server flag, expected open)
    private nonisolated static let reconnectRows: [(offset: TimeInterval, flag: Bool?, open: Bool)] = [
        (1800, true, true),     // end + 30 min with true
        (1800, false, false),
        (1800, nil, false),
        (3600, true, true),     // end + 60:00 with true, inclusive
        (3601, true, false),    // end + 60:01 with true
        (3601, false, false),
        (3601, nil, false)
    ]

    @Test("2-hour session: reconnect tier follows the server flag", arguments: reconnectRows)
    func reconnectTier(row: (offset: TimeInterval, flag: Bool?, open: Bool)) {
        let open = Self.isOpen(
            sessionMinutes: 120,
            offset: row.offset,
            relativeTo: .end,
            serverCanJoin: row.flag
        )
        #expect(open == row.open)
    }

    @Test("The server flag never opens Join before the lead edge")
    func flagDoesNotOpenEarly() {
        #expect(!Self.isOpen(sessionMinutes: 120, offset: -3601, serverCanJoin: true))
    }

    @Test("The server flag does not extend a short session past end + 60 minutes")
    func flagOnShortSession() {
        // 30-minute session: end + 60:00 is start + 90 min.
        #expect(Self.isOpen(sessionMinutes: 30, offset: 3600, relativeTo: .end, serverCanJoin: true))
        #expect(!Self.isOpen(sessionMinutes: 30, offset: 3601, relativeTo: .end, serverCanJoin: true))
    }

    // MARK: - Status matrix

    private nonisolated static let joinable: [BookingStatus] = [.confirmed, .inProgress, .completed]
    private nonisolated static let notJoinable: [BookingStatus] = [
        .pendingApproval, .pendingReschedule, .cancelled, .declined,
        .missed, .expired, .rescheduled, .unknown
    ]

    @Test("Joinable statuses are open at start", arguments: joinable)
    func joinableStatusesOpen(status: BookingStatus) {
        #expect(JoinWindow.isJoinableStatus(status))
        #expect(Self.isOpen(status, sessionMinutes: 30, offset: 0))
    }

    @Test("Other statuses are never open, with or without the server flag", arguments: notJoinable)
    func otherStatusesClosed(status: BookingStatus) {
        #expect(!JoinWindow.isJoinableStatus(status))
        #expect(!Self.isOpen(status, sessionMinutes: 30, offset: 0))
        #expect(!Self.isOpen(status, sessionMinutes: 30, offset: 0, serverCanJoin: true))
        #expect(!Self.isOpen(status, sessionMinutes: 120, offset: 30 * Self.minute, serverCanJoin: true))
    }

    @Test("Every BookingStatus case is classified")
    func matrixCoversEveryCase() {
        #expect(Set(Self.joinable + Self.notJoinable).count == Self.joinable.count + Self.notJoinable.count)
        #expect(Self.joinable.count + Self.notJoinable.count == 11)
    }
}
