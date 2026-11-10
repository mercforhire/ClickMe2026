//
//  RescheduleWindowTests.swift
//  ClickMe2026Tests
//
//  BOOK-14 on the reschedule pickers: the client picker caps a paid booking
//  at 6 days ahead (D-13), free bookings are not capped, and a booking
//  counts as paid from payment_status or from a non-free topic (a long-lead
//  paid booking has no PaymentIntent yet and reads payment_status none).
//
//  These rows never reach the API and must not touch MockURLProtocol.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Reschedule window")
struct RescheduleWindowTests {

    private static let day: TimeInterval = 24 * 3600

    private func dateKey(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    // MARK: - Paid flag

    @Test("a booking is paid when payment_status is not none or the topic is not free")
    func paidFlag() {
        #expect(!PaidBookingWindow.isPaidReschedule(paymentStatus: "none", topicIsFree: true))
        #expect(PaidBookingWindow.isPaidReschedule(paymentStatus: "none", topicIsFree: false))
        #expect(PaidBookingWindow.isPaidReschedule(paymentStatus: "held", topicIsFree: false))
        #expect(PaidBookingWindow.isPaidReschedule(paymentStatus: "captured", topicIsFree: true))
    }

    // MARK: - Paid booking

    @Test("a paid booking can move to exactly now + 6 days but not one second later")
    func paidEdge() {
        let viewModel = RescheduleViewModel(isPaidBooking: true)
        let now = Date()
        #expect(viewModel.isBookableStart(now.addingTimeInterval(6 * Self.day)))
        #expect(!viewModel.isBookableStart(now.addingTimeInterval(6 * Self.day + 1)))
    }

    @Test("the day after the limit is beyond the window and has no slots")
    func dayAfterLimit() throws {
        let viewModel = RescheduleViewModel(isPaidBooking: true)
        let calendar = viewModel.calendar
        let limitDay = Date().addingTimeInterval(6 * Self.day)
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: limitDay))
        let startOfNextDay = calendar.startOfDay(for: nextDay)

        #expect(viewModel.isBeyondBookingWindow(startOfNextDay))

        // Even with an available slot that day, the day reads as empty.
        let slot = BookingTimeSlot(startTime: nextDay, endTime: nil, isAvailable: true)
        viewModel.availabilityByDate = [dateKey(nextDay, calendar: calendar): [slot]]
        #expect(!viewModel.hasSlots(on: startOfNextDay))

        viewModel.selectedDate = nextDay
        #expect(viewModel.slotsForSelectedDate.isEmpty)
    }

    @Test("a day inside the limit keeps its slots for a paid booking")
    func dayInsideLimit() {
        let viewModel = RescheduleViewModel(isPaidBooking: true)
        let near = BookingTimeSlot(startTime: Date().addingTimeInterval(2 * Self.day), endTime: nil, isAvailable: true)
        viewModel.availabilityByDate = [dateKey(near.startTime, calendar: viewModel.calendar): [near]]
        #expect(!viewModel.isBeyondBookingWindow(near.startTime))
        #expect(viewModel.hasSlots(on: near.startTime))
        viewModel.selectedDate = near.startTime
        #expect(viewModel.slotsForSelectedDate == [near])
    }

    // MARK: - Free booking

    @Test("a free booking is not capped")
    func freeBookingNotCapped() {
        let viewModel = RescheduleViewModel(isPaidBooking: false)
        let far = Date().addingTimeInterval(30 * Self.day)
        #expect(viewModel.isBookableStart(far))
        #expect(!viewModel.isBeyondBookingWindow(far))

        let slot = BookingTimeSlot(startTime: far, endTime: nil, isAvailable: true)
        viewModel.availabilityByDate = [dateKey(far, calendar: viewModel.calendar): [slot]]
        #expect(viewModel.hasSlots(on: far))
    }

    @Test("the runtime view model is not capped before the detail loads")
    func runtimeDefaultsToUncapped() {
        let viewModel = RescheduleViewModel(bookingId: UUID())
        #expect(!viewModel.isPaidBooking)
        #expect(viewModel.isBookableStart(Date().addingTimeInterval(30 * Self.day)))
    }
}
