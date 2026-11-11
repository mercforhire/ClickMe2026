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

    // MARK: - Reschedule (mirrors canReschedule in reschedule.js)

    private let rescheduleAnytime: [BookingStatus] = [.confirmed, .pendingApproval, .pendingReschedule]
    private let rescheduleWhileAhead: [BookingStatus] = [.completed, .inProgress]
    private let notReschedulable: [BookingStatus] = [
        .cancelled, .declined, .missed, .expired, .rescheduled, .unknown
    ]

    @Test("the no-time-gate statuses show Reschedule at any end time")
    func rescheduleAnytime_shows() {
        for status in rescheduleAnytime {
            #expect(UpcomingActionPolicy.canShowReschedule(status: status, end: now.addingTimeInterval(1), now: now), "\(status)")
            #expect(UpcomingActionPolicy.canShowReschedule(status: status, end: now.addingTimeInterval(-3600), now: now), "\(status)")
            #expect(UpcomingActionPolicy.canShowReschedule(status: status, end: nil, now: now), "\(status)")
        }
    }

    @Test("completed and in-progress show Reschedule only while the end is ahead")
    func rescheduleTimeGated() {
        for status in rescheduleWhileAhead {
            #expect(UpcomingActionPolicy.canShowReschedule(status: status, end: now.addingTimeInterval(1), now: now), "\(status)")
            #expect(!UpcomingActionPolicy.canShowReschedule(status: status, end: now, now: now), "\(status)")
            #expect(!UpcomingActionPolicy.canShowReschedule(status: status, end: now.addingTimeInterval(-1), now: now), "\(status)")
            #expect(!UpcomingActionPolicy.canShowReschedule(status: status, end: nil, now: now), "\(status)")
        }
    }

    @Test("cancelled, declined, missed, expired, rescheduled and unknown never show Reschedule")
    func rescheduleHiddenForRefusedStatuses() {
        let end = now.addingTimeInterval(3600)
        for status in notReschedulable {
            #expect(!UpcomingActionPolicy.canShowReschedule(status: status, end: end, now: now), "\(status)")
        }
    }

    @Test("the reschedule lists cover every status the app knows")
    func rescheduleListsAreExhaustive() {
        #expect(UpcomingActionPolicy.reschedulableStatuses == Set(rescheduleAnytime))
        #expect(UpcomingActionPolicy.timeGatedReschedulableStatuses == Set(rescheduleWhileAhead))
        let all = Set(rescheduleAnytime).union(rescheduleWhileAhead).union(notReschedulable)
        #expect(all == Set(cancellable).union(notCancellable))
    }

    @Test("the two lists cover every status the app knows")
    func listsAreExhaustive() {
        #expect(UpcomingActionPolicy.cancellableStatuses == Set(cancellable))
        #expect(Set(cancellable).union(notCancellable).count == cancellable.count + notCancellable.count)
    }
}
