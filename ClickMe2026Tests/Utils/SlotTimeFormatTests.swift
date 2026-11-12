//
//  SlotTimeFormatTests.swift
//  ClickMe2026Tests
//
//  BOOK-03 / BOOK-04: slot and session times follow the device's 12/24-hour
//  style, and the zone label is a readable name, never an IANA identifier.
//
//  Every locale is passed explicitly. The test plan runs in region GB, and
//  en_US short time puts U+202F (narrow no-break space) before AM/PM, so
//  expectations compare exact Unicode scalars rather than a typed space.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Slot time format")
@MainActor
struct SlotTimeFormatTests {

    private let enUS = Locale(identifier: "en_US")
    private let enGB = Locale(identifier: "en_GB")

    /// 2026-10-24 at the given UTC hour and minute.
    private func utc(hour: Int, minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.utc
        return calendar.date(from: DateComponents(
            timeZone: TimeZone.utc, year: 2026, month: 10, day: 24, hour: hour, minute: minute
        ))!
    }

    @Test("shortTime: a 12-hour locale shows 2:00 PM with a narrow no-break space")
    func twelveHour() {
        let text = DateUtil.shortTime(utc(hour: 14), timeZone: .utc, locale: enUS)
        #expect(text == "2:00\u{202F}PM")
    }

    @Test("shortTime: a 24-hour locale shows 14:00")
    func twentyFourHour() {
        #expect(DateUtil.shortTime(utc(hour: 14), timeZone: .utc, locale: enGB) == "14:00")
    }

    @Test("shortTime: a 24-hour locale keeps the leading zero")
    func twentyFourHourLeadingZero() {
        #expect(DateUtil.shortTime(utc(hour: 9, minute: 5), timeZone: .utc, locale: enGB) == "09:05")
    }

    @Test("zoneName: a readable name with no slash")
    func zoneNameIsReadable() throws {
        let toronto = try #require(TimeZone(identifier: "America/Toronto"))
        let name = try #require(DateUtil.zoneName(for: toronto, locale: enUS))
        #expect(name == "Eastern Time")
        #expect(!name.contains("/"))
    }

    @Test("normalizedZoneName: nil, empty and whitespace are nil; a name passes through")
    func normalizedZoneName() {
        #expect(DateUtil.normalizedZoneName(nil) == nil)
        #expect(DateUtil.normalizedZoneName("") == nil)
        #expect(DateUtil.normalizedZoneName("  ") == nil)
        #expect(DateUtil.normalizedZoneName("Eastern Time") == "Eastern Time")
    }

    @Test("BookingTimeSlot.displayLabel is the shared short time of its start")
    func displayLabelMatchesShortTime() {
        let start = utc(hour: 14)
        let slot = BookingTimeSlot(startTime: start, endTime: nil, isAvailable: true)
        #expect(slot.displayLabel == DateUtil.shortTime(start))
    }
}
