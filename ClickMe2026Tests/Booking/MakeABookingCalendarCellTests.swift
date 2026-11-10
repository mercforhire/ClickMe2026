//
//  MakeABookingCalendarCellTests.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//
//  02-UI-SPEC A1: the Make a Booking calendar hides only its grid-padding
//  cells (adjacent-month numbers) from VoiceOver. Every day of the displayed
//  month, including days past the paid 6-day limit, stays announced.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("MakeABooking calendar cells")
struct MakeABookingCalendarCellTests {

    private let freeTopic = BookingTopic(
        id: UUID(), title: "Free chat", durationMinutes: 30, description: nil,
        priceAmount: nil, currency: nil, isFree: true
    )
    private let paidTopic = BookingTopic(
        id: UUID(), title: "Paid session", durationMinutes: 30, description: nil,
        priceAmount: 5000, currency: "USD", isFree: false
    )

    /// These rows never reach the API, so they do not touch `MockURLProtocol`.
    private func makeViewModel(selecting topic: BookingTopic) -> MakeABookingViewModel {
        let viewModel = MakeABookingViewModel(
            expertName: "Ada Lovelace",
            expertTitle: "Engineer",
            expertImageURL: "",
            topics: [freeTopic, paidTopic]
        )
        viewModel.selectedTopic = topic
        return viewModel
    }

    /// First day of the given month, built with the view model's own calendar
    /// so the rows hold in any device time zone.
    private func month(_ year: Int, _ month: Int, in calendar: Calendar) throws -> Date {
        let components = DateComponents(year: year, month: month, day: 1)
        return try #require(calendar.date(from: components))
    }

    private func dayCount(of month: Date, in calendar: Calendar) throws -> Int {
        try #require(calendar.range(of: .day, in: .month, for: month)).count
    }

    @Test("filler cells are exactly the cells with no date")
    func fillersAreDatelessCells() throws {
        let viewModel = makeViewModel(selecting: freeTopic)
        // February and October 2026 end on a Saturday, so they carry the
        // extra trailing cell, which must count as a filler too.
        for (year, monthNumber) in [(2026, 11), (2026, 2), (2026, 10)] {
            let days = viewModel.generateDays(for: try month(year, monthNumber, in: viewModel.calendar))
            #expect(!days.isEmpty)
            for day in days {
                #expect(day.isFiller == (day.date == nil))
                if day.isFiller {
                    #expect(!day.isCurrentMonth)
                } else {
                    #expect(day.isCurrentMonth)
                }
            }
        }
    }

    @Test("every day of the displayed month stays announced")
    func everyInMonthDayIsNotAFiller() throws {
        let viewModel = makeViewModel(selecting: freeTopic)
        let calendar = viewModel.calendar
        for (year, monthNumber) in [(2026, 11), (2026, 2), (2026, 10)] {
            let first = try month(year, monthNumber, in: calendar)
            let expectedCount = try dayCount(of: first, in: calendar)
            let announced = viewModel.generateDays(for: first).filter { !$0.isFiller }
            let dayNumbers = announced.compactMap { $0.date.map { calendar.component(.day, from: $0) } }
            #expect(dayNumbers == Array(1 ... expectedCount))
        }
    }

    @Test("days past the paid limit are never fillers")
    func daysPastPaidLimitStayAnnounced() throws {
        let viewModel = makeViewModel(selecting: paidTopic)
        let calendar = viewModel.calendar
        let latestStart = try #require(viewModel.latestBookableStart)
        let farMonth = try #require(calendar.date(byAdding: .month, value: 2, to: Date()))
        let first = try #require(calendar.date(from: calendar.dateComponents([.year, .month], from: farMonth)))
        let expectedCount = try dayCount(of: first, in: calendar)

        let inMonth = viewModel.generateDays(for: first).filter { $0.isCurrentMonth }
        let dates = inMonth.compactMap(\.date)
        #expect(dates.count == expectedCount)
        // Proves the row really covers days past the limit.
        for date in dates {
            #expect(PaidBookingWindow.isDayBeyond(date, latestStart: latestStart, calendar: calendar))
        }
        #expect(inMonth.allSatisfy { !$0.isFiller })
        let announced = viewModel.generateDays(for: first).filter { !$0.isFiller }
        #expect(announced.count == expectedCount)
    }
}
