//
//  PaidBookingWindowTests.swift
//  ClickMe2026Tests
//
//  BOOK-14: a paid booking can start at most 6 days ahead (the server refuses
//  a start strictly more than 6 days out). The Make a Booking picker hides
//  slots and days past that; free topics are not capped.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("PaidBookingWindow")
struct PaidBookingWindowTests {

    private static let day: TimeInterval = 24 * 3600
    /// A fixed "now", so every boundary is exact.
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test("a free topic has no limit")
    func freeTopicHasNoLimit() {
        let latest = PaidBookingWindow.latestStart(isPaid: false, now: Self.now)
        #expect(latest == nil)
        #expect(PaidBookingWindow.allows(Self.now.addingTimeInterval(30 * Self.day), latestStart: latest))
    }

    @Test("a paid topic ends at exactly now + 6 days, inclusive")
    func paidEdge() {
        let latest = PaidBookingWindow.latestStart(isPaid: true, now: Self.now)
        #expect(latest == Self.now.addingTimeInterval(6 * Self.day))
        #expect(PaidBookingWindow.allows(Self.now, latestStart: latest))
        #expect(PaidBookingWindow.allows(Self.now.addingTimeInterval(6 * Self.day), latestStart: latest))
        #expect(!PaidBookingWindow.allows(Self.now.addingTimeInterval(6 * Self.day + 1), latestStart: latest))
    }

    @Test("the limit follows the clock passed in, so it moves with time")
    func limitMovesWithNow() {
        let later = Self.now.addingTimeInterval(Self.day)
        let first = PaidBookingWindow.latestStart(isPaid: true, now: Self.now)
        let second = PaidBookingWindow.latestStart(isPaid: true, now: later)
        let start = Self.now.addingTimeInterval(6 * Self.day + 3600)
        #expect(!PaidBookingWindow.allows(start, latestStart: first))
        #expect(PaidBookingWindow.allows(start, latestStart: second))
    }

    @Test("a day is beyond only when it starts after the limit")
    func dayBeyond() throws {
        let latest = PaidBookingWindow.latestStart(isPaid: true, now: Self.now)
        let limitDay = Self.now.addingTimeInterval(6 * Self.day)
        let nextDay = try #require(Self.calendar.date(byAdding: .day, value: 1, to: limitDay))

        #expect(!PaidBookingWindow.isDayBeyond(limitDay, latestStart: latest, calendar: Self.calendar))
        #expect(PaidBookingWindow.isDayBeyond(nextDay, latestStart: latest, calendar: Self.calendar))
        #expect(!PaidBookingWindow.isDayBeyond(nextDay, latestStart: nil, calendar: Self.calendar))
    }
}

/// View-model rows live inside `PaidBookingWindowTests` so one
/// `-only-testing:` filter runs both.
extension PaidBookingWindowTests {

@MainActor
@Suite("MakeABookingViewModel paid window", .serialized)
struct ViewModelRows {

    private static let day: TimeInterval = 24 * 3600

    private let freeTopic = BookingTopic(
        id: UUID(), title: "Free chat", durationMinutes: 30, description: nil,
        priceAmount: nil, currency: nil, isFree: true
    )
    private let paidTopic = BookingTopic(
        id: UUID(), title: "Paid session", durationMinutes: 30, description: nil,
        priceAmount: 5000, currency: "USD", isFree: false
    )

    /// These rows never reach the API, and they must not touch
    /// `MockURLProtocol`: its handler is shared, and the parity suite is
    /// waiting on it while this one runs.
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

    private func slot(daysAhead: Double) -> BookingTimeSlot {
        BookingTimeSlot(startTime: Date().addingTimeInterval(daysAhead * Self.day), endTime: nil, isAvailable: true)
    }

    private func dateKey(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    @Test("a paid topic offers starts within 6 days and refuses later ones")
    func paidTopicBookableStarts() {
        let viewModel = makeViewModel(selecting: paidTopic)
        #expect(viewModel.isBookableStart(Date().addingTimeInterval(5 * Self.day)))
        #expect(!viewModel.isBookableStart(Date().addingTimeInterval(7 * Self.day)))
    }

    @Test("a free topic is not capped")
    func freeTopicNotCapped() {
        let viewModel = makeViewModel(selecting: freeTopic)
        #expect(viewModel.isBookableStart(Date().addingTimeInterval(30 * Self.day)))
        #expect(!viewModel.isBeyondBookingWindow(Date().addingTimeInterval(30 * Self.day)))
    }

    @Test("the calendar blanks days past the limit for a paid topic only")
    func beyondDays() {
        let viewModel = makeViewModel(selecting: paidTopic)
        #expect(!viewModel.isBeyondBookingWindow(Date().addingTimeInterval(2 * Self.day)))
        #expect(viewModel.isBeyondBookingWindow(Date().addingTimeInterval(8 * Self.day)))
    }

    @Test("slotsForSelectedDate drops slots past the limit for a paid topic")
    func slotsAreFiltered() {
        let near = slot(daysAhead: 1)
        let viewModel = makeViewModel(selecting: freeTopic)
        let far = slot(daysAhead: 7)
        viewModel.selectedDate = far.startTime
        viewModel.availabilityByDate = [dateKey(far.startTime, calendar: viewModel.calendar): [far]]
        #expect(viewModel.slotsForSelectedDate == [far])

        viewModel.selectedTopic = paidTopic
        #expect(viewModel.slotsForSelectedDate.isEmpty)

        viewModel.selectedDate = near.startTime
        viewModel.availabilityByDate = [dateKey(near.startTime, calendar: viewModel.calendar): [near]]
        #expect(viewModel.slotsForSelectedDate == [near])
    }

    @Test("switching from a free topic to a paid topic clears a slot past the limit")
    func switchingTopicClearsFarSlot() {
        let viewModel = makeViewModel(selecting: freeTopic)
        viewModel.selectedTimeSlot = slot(daysAhead: 7)
        viewModel.selectedTopic = paidTopic
        #expect(viewModel.selectedTimeSlot == nil)
    }

    @Test("switching topics keeps a slot that is still within the limit")
    func switchingTopicKeepsNearSlot() {
        let viewModel = makeViewModel(selecting: freeTopic)
        let near = slot(daysAhead: 2)
        viewModel.selectedTimeSlot = near
        viewModel.selectedTopic = paidTopic
        #expect(viewModel.selectedTimeSlot == near)
    }
}
}
