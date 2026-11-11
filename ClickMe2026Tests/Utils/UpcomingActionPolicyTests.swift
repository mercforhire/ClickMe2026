//
//  UpcomingActionPolicyTests.swift
//  ClickMe2026Tests
//
//  BOOK-13 / D-13: Cancel shows only where the server would accept it. The
//  matrix is every BookingStatus case against an end time before, at and after
//  `now`.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Upcoming action policy")
@MainActor
struct UpcomingActionPolicyTests {

    private let now = Date(timeIntervalSince1970: 4_070_000_000)

    private let cancellable: [BookingStatus] = [.confirmed, .pendingApproval, .pendingReschedule]
    private let notCancellable: [BookingStatus] = [
        .inProgress, .completed, .cancelled, .declined, .missed, .expired, .rescheduled, .unknown
    ]

    @Test("a cancellable status with the session still ahead shows Cancel")
    func showsWhileEndIsAhead() {
        for status in cancellable {
            let end = now.addingTimeInterval(1)
            #expect(UpcomingActionPolicy.canShowCancel(status: status, end: end, now: now), "\(status)")
            let later = now.addingTimeInterval(86_400)
            #expect(UpcomingActionPolicy.canShowCancel(status: status, end: later, now: now), "\(status)")
        }
    }

    @Test("a cancellable status hides Cancel at end == now and after it")
    func hidesAtAndAfterEnd() {
        for status in cancellable {
            #expect(!UpcomingActionPolicy.canShowCancel(status: status, end: now, now: now), "\(status)")
            let before = now.addingTimeInterval(-1)
            #expect(!UpcomingActionPolicy.canShowCancel(status: status, end: before, now: now), "\(status)")
        }
    }

    @Test("a status the server refuses hides Cancel even with the end in the future")
    func hidesForOtherStatuses() {
        let end = now.addingTimeInterval(3600)
        for status in notCancellable {
            #expect(!UpcomingActionPolicy.canShowCancel(status: status, end: end, now: now), "\(status)")
        }
    }

    @Test("an unknown end time hides Cancel")
    func hidesWithoutEnd() {
        for status in cancellable {
            #expect(!UpcomingActionPolicy.canShowCancel(status: status, end: nil, now: now), "\(status)")
        }
    }

    @Test("the two lists cover every status the app knows")
    func listsAreExhaustive() {
        #expect(UpcomingActionPolicy.cancellableStatuses == Set(cancellable))
        #expect(Set(cancellable).union(notCancellable).count == cancellable.count + notCancellable.count)
    }
}
