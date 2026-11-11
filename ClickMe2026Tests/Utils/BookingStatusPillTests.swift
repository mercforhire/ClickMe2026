//
//  BookingStatusPillTests.swift
//  ClickMe2026Tests
//
//  BOOK-09: the Upcoming details pill is decided by the decoded `BookingStatus`
//  case. A status this build does not know is never shown as Confirmed or in
//  the accent tone (BOOK-18). Pure rows, no API.
//

import Testing
@testable import ClickMe2026

@MainActor
@Suite("Booking status pill")
struct BookingStatusPillTests {

    private static let allCases: [BookingStatus] = [
        .pendingApproval, .confirmed, .pendingReschedule, .inProgress, .completed,
        .cancelled, .declined, .missed, .expired, .rescheduled, .unknown,
    ]

    /// The expected pill for a known case. The switch has no `default`, so adding
    /// a `BookingStatus` case fails to compile here until its row is written.
    private static func expected(for status: BookingStatus) -> BookingStatusPill? {
        switch status {
        case .confirmed: return BookingStatusPill(text: "Confirmed", tone: .accent)
        case .inProgress: return BookingStatusPill(text: "In progress", tone: .accent)
        case .completed: return BookingStatusPill(text: "Completed", tone: .accent)
        case .pendingApproval: return BookingStatusPill(text: "Pending approval", tone: .amber)
        case .pendingReschedule: return BookingStatusPill(text: "Pending reschedule", tone: .amber)
        case .cancelled, .declined: return BookingStatusPill(text: "Cancelled", tone: .neutral)
        case .missed, .expired: return BookingStatusPill(text: "Missed", tone: .neutral)
        case .rescheduled: return BookingStatusPill(text: "Rescheduled", tone: .neutral)
        case .unknown: return nil
        }
    }

    @Test("every known case maps to its text and tone, whatever the raw string says")
    func knownCases() {
        var checked = 0
        for status in Self.allCases {
            guard let expected = Self.expected(for: status) else { continue }
            #expect(BookingStatusPill.make(status: status, rawStatus: "garbage") == expected, "\(status)")
            #expect(BookingStatusPill.make(status: status, rawStatus: "") == expected, "\(status)")
            checked += 1
        }
        #expect(checked == 10)
    }

    @Test("a known case ignores the raw string: confirmed with raw 'garbage' stays Confirmed, accent")
    func knownCaseIgnoresRaw() {
        let pill = BookingStatusPill.make(status: .confirmed, rawStatus: "garbage")
        #expect(pill == BookingStatusPill(text: "Confirmed", tone: .accent))
    }

    @Test("an unknown status is humanized from the raw string, neutral")
    func unknownIsHumanized() {
        let pill = BookingStatusPill.make(status: .unknown, rawStatus: "awaiting_payment")
        #expect(pill == BookingStatusPill(text: "Awaiting payment", tone: .neutral))
    }

    @Test("an unknown status with an empty or blank raw string reads Unknown, neutral")
    func unknownEmptyRaw() {
        #expect(BookingStatusPill.make(status: .unknown, rawStatus: "") == BookingStatusPill(text: "Unknown", tone: .neutral))
        #expect(BookingStatusPill.make(status: .unknown, rawStatus: "  ") == BookingStatusPill(text: "Unknown", tone: .neutral))
    }

    @Test("an unknown status is never accent and never reads Confirmed")
    func unknownNeverConfirmed() {
        for raw in ["", "confirmed_soon", "awaiting_payment", "new_state"] {
            let pill = BookingStatusPill.make(status: .unknown, rawStatus: raw)
            #expect(pill.tone == .neutral, "\(raw)")
            #expect(pill.text != "Confirmed", "\(raw)")
        }
    }
}
