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
}
