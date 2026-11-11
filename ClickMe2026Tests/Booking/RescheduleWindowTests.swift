//
//  RescheduleWindowTests.swift
//  ClickMe2026Tests
//
//  BOOK-14 on the reschedule pickers: the client picker caps a paid booking
//  at 6 days ahead (D-13), free bookings are not capped, and a booking
//  counts as paid from payment_status or from a non-free topic (a long-lead
//  paid booking has no PaymentIntent yet and reads payment_status none).
//
//  Android parity (user decision 2026-11-10): every day stays visible and
//  tappable, slots past the limit stay listed but cannot be selected, and a
//  paid booking shows a fixed window note.
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

    @Test("a paid booking shows the paid window note")
    func paidBookingShowsNote() {
        #expect(RescheduleViewModel(isPaidBooking: true).latestBookableStart != nil)
    }

    @Test("the day after the limit stays tappable, lists its slots, and none can be selected")
    func dayAfterLimit() throws {
        let viewModel = RescheduleViewModel(isPaidBooking: true)
        let calendar = viewModel.calendar
        let limitDay = Date().addingTimeInterval(6 * Self.day)
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: limitDay))

        let slot = BookingTimeSlot(startTime: nextDay, endTime: nil, isAvailable: true)
        viewModel.availabilityByDate = [dateKey(nextDay, calendar: calendar): [slot]]

        // The day is not blanked or disabled: it has an available slot.
        #expect(viewModel.hasSlots(on: calendar.startOfDay(for: nextDay)))

        // Its slot is listed, dimmed, and refused when pushed directly.
        viewModel.selectedDate = nextDay
        #expect(viewModel.slotsForSelectedDate == [slot])
        #expect(!viewModel.isSelectableSlot(slot))
        #expect(viewModel.slotsForSelectedDate.filter { viewModel.isSelectableSlot($0) }.isEmpty)
        viewModel.select(time: slot)
        #expect(viewModel.selectedTime == nil)
    }

    @Test("a day inside the limit keeps its slots selectable for a paid booking")
    func dayInsideLimit() {
        let viewModel = RescheduleViewModel(isPaidBooking: true)
        let near = BookingTimeSlot(startTime: Date().addingTimeInterval(2 * Self.day), endTime: nil, isAvailable: true)
        viewModel.availabilityByDate = [dateKey(near.startTime, calendar: viewModel.calendar): [near]]
        #expect(viewModel.hasSlots(on: near.startTime))
        viewModel.selectedDate = near.startTime
        #expect(viewModel.slotsForSelectedDate == [near])
        #expect(viewModel.isSelectableSlot(near))
        viewModel.select(time: near)
        #expect(viewModel.selectedTime == near)
    }

    @Test("an unavailable or already started slot is never selectable")
    func unavailableOrPastSlot() {
        let viewModel = RescheduleViewModel(isPaidBooking: true)
        let taken = BookingTimeSlot(startTime: Date().addingTimeInterval(Self.day), endTime: nil, isAvailable: false)
        let past = BookingTimeSlot(startTime: Date().addingTimeInterval(-3600), endTime: nil, isAvailable: true)
        #expect(!viewModel.isSelectableSlot(taken))
        #expect(!viewModel.isSelectableSlot(past))
    }

    // MARK: - Free booking

    @Test("a free booking is not capped and shows no paid window note")
    func freeBookingNotCapped() {
        let viewModel = RescheduleViewModel(isPaidBooking: false)
        let far = Date().addingTimeInterval(30 * Self.day)
        #expect(viewModel.isBookableStart(far))
        #expect(viewModel.latestBookableStart == nil)

        let slot = BookingTimeSlot(startTime: far, endTime: nil, isAvailable: true)
        viewModel.availabilityByDate = [dateKey(far, calendar: viewModel.calendar): [slot]]
        #expect(viewModel.hasSlots(on: far))
        #expect(viewModel.isSelectableSlot(slot))
        viewModel.selectedDate = far
        viewModel.select(time: slot)
        #expect(viewModel.selectedTime == slot)
    }

    @Test("the runtime view model is not capped before the detail loads")
    func runtimeDefaultsToUncapped() {
        let viewModel = RescheduleViewModel(bookingId: UUID())
        #expect(!viewModel.isPaidBooking)
        #expect(viewModel.latestBookableStart == nil)
        #expect(viewModel.isBookableStart(Date().addingTimeInterval(30 * Self.day)))
    }
}

/// Error-copy rows live inside `RescheduleWindowTests` so one
/// `-only-testing:` filter runs both suites.
extension RescheduleWindowTests {

@MainActor
@Suite("Reschedule error copy")
struct ErrorCopyRows {

    private static let slotTaken = "That time slot was just taken. Please pick another."
    private static let clientOutsideAuthWindow =
        "This time is past the payment hold on your original booking. Choose a different time, or cancel this booking and book again. Cancelling releases the hold on your card, so you won't be charged."
    private static let clientPaymentMethodRequired =
        "The card on file can't be used for this reschedule. Please add a new payment method in Profile > Payment and try again."
    private static let expertOutsideAuthWindow =
        "This time is past the payment hold on the original booking. Please cancel and ask the client to book a new session."

    /// A `NetworkError.httpError` carrying the standard error body.
    private func httpError(status: Int = 422, code: String, message: String = "server text") -> NetworkError {
        let body = #"{"status":"error","code":"\#(code)","message":"\#(message)"}"#
        return .httpError(statusCode: status, data: Data(body.utf8))
    }

    // MARK: - Client

    @Test("client: RESCHEDULE_TOO_FAR_AHEAD shows the shared reschedule copy")
    func clientTooFarAhead() {
        #expect(RescheduleViewModel.rescheduleErrorMessage(for: httpError(code: "RESCHEDULE_TOO_FAR_AHEAD"))
            == BookingErrorMapper.rescheduleTooFarAheadMessage)
    }

    @Test("client: the two reschedule-only codes keep their client copy")
    func clientKeepsOwnCopy() {
        #expect(RescheduleViewModel.rescheduleErrorMessage(for: httpError(code: "RESCHEDULE_OUTSIDE_AUTH_WINDOW"))
            == Self.clientOutsideAuthWindow)
        #expect(RescheduleViewModel.rescheduleErrorMessage(for: httpError(code: "PAYMENT_METHOD_REQUIRED"))
            == Self.clientPaymentMethodRequired)
    }

    @Test("client: SLOT_UNAVAILABLE reads the same as on Make a Booking")
    func clientSlotUnavailable() {
        #expect(RescheduleViewModel.rescheduleErrorMessage(for: httpError(status: 409, code: "SLOT_UNAVAILABLE"))
            == Self.slotTaken)
    }

    @Test("client: an unmapped code shows the server message")
    func clientUnmappedCode() {
        #expect(RescheduleViewModel.rescheduleErrorMessage(for: httpError(status: 400, code: "SOMETHING_ELSE"))
            == "server text")
    }

    // MARK: - Expert

    @Test("expert: RESCHEDULE_TOO_FAR_AHEAD shows the shared reschedule copy")
    func expertTooFarAhead() {
        #expect(ExpertRescheduleViewModel.rescheduleErrorMessage(for: httpError(code: "RESCHEDULE_TOO_FAR_AHEAD"))
            == BookingErrorMapper.rescheduleTooFarAheadMessage)
    }

    @Test("expert: RESCHEDULE_OUTSIDE_AUTH_WINDOW keeps its expert copy")
    func expertKeepsOwnCopy() {
        #expect(ExpertRescheduleViewModel.rescheduleErrorMessage(for: httpError(code: "RESCHEDULE_OUTSIDE_AUTH_WINDOW"))
            == Self.expertOutsideAuthWindow)
    }

    @Test("expert: an unmapped code shows the server message")
    func expertUnmappedCode() {
        #expect(ExpertRescheduleViewModel.rescheduleErrorMessage(for: httpError(status: 400, code: "SOMETHING_ELSE"))
            == "server text")
    }
}
}
