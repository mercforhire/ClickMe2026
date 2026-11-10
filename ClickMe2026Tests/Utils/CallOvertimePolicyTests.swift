//
//  CallOvertimePolicyTests.swift
//  ClickMe2026Tests
//
//  Pins the overtime cutoff (end + 60 min), the warning lead (5 min) and the
//  `/end` duration rules (CALL-01, CALL-04). A testing constant of 5 minutes
//  once shipped in the cutoff and cut every call off; these tests fail if the
//  boundary moves.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("CallOvertimePolicy")
struct CallOvertimePolicyTests {

    private static let end = Date(timeIntervalSince1970: 1_800_000_000)

    private static func at(_ offset: TimeInterval) -> Date {
        end.addingTimeInterval(offset)
    }

    private static let nilEndOffsets: [TimeInterval] = [-600, 0, 3299, 3300, 3600, 7200]
    private static let quietOffsets: [TimeInterval] = [-600, 0, 54 * 60 + 59]
    private static let warnOffsets: [TimeInterval] = [55 * 60, 59 * 60 + 59]
    private static let endOffsets: [TimeInterval] = [60 * 60, 2 * 60 * 60]

    @Test("constants are pinned")
    func constants() {
        #expect(CallOvertimePolicy.cutoff == 3600)
        #expect(CallOvertimePolicy.warningLead == 300)
    }

    @Test("nil scheduled end never acts", arguments: Self.nilEndOffsets)
    func nilEndIsNone(offset: TimeInterval) {
        #expect(CallOvertimePolicy.action(scheduledEnd: nil, now: Self.at(offset)) == .none)
    }

    @Test("before end + 55 min is none", arguments: Self.quietOffsets)
    func beforeWarning(offset: TimeInterval) {
        #expect(CallOvertimePolicy.action(scheduledEnd: Self.end, now: Self.at(offset)) == .none)
    }

    @Test("end + 55 min up to end + 59:59 warns", arguments: Self.warnOffsets)
    func warningWindow(offset: TimeInterval) {
        #expect(CallOvertimePolicy.action(scheduledEnd: Self.end, now: Self.at(offset)) == .warn)
    }

    @Test("end + 60 min and later ends", arguments: Self.endOffsets)
    func cutoffReached(offset: TimeInterval) {
        #expect(CallOvertimePolicy.action(scheduledEnd: Self.end, now: Self.at(offset)) == .end)
    }

    // MARK: - endDuration

    private static let legStart = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("a leg that never joined reports no duration")
    func neverJoinedIsNil() {
        #expect(CallOvertimePolicy.endDuration(joinStart: nil, now: Self.legStart) == nil)
    }

    @Test("a sub-second or zero-second leg reports 1", arguments: [0.0, 0.4, 0.999] as [TimeInterval])
    func shortLegIsClampedToOne(seconds: TimeInterval) {
        let now = Self.legStart.addingTimeInterval(seconds)
        #expect(CallOvertimePolicy.endDuration(joinStart: Self.legStart, now: now) == 1)
    }

    @Test("a clock that ran backwards still reports 1")
    func negativeLegIsClampedToOne() {
        let now = Self.legStart.addingTimeInterval(-5)
        #expect(CallOvertimePolicy.endDuration(joinStart: Self.legStart, now: now) == 1)
    }

    @Test("a longer leg is truncated to whole seconds")
    func longLegTruncates() {
        let now = Self.legStart.addingTimeInterval(125.9)
        #expect(CallOvertimePolicy.endDuration(joinStart: Self.legStart, now: now) == 125)
    }
}
