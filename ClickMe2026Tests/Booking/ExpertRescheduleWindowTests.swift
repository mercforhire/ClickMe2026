//
//  ExpertRescheduleWindowTests.swift
//  ClickMe2026Tests
//
//  EXP-13 (Phase 2 D-13): the expert reschedule picker caps a paid booking at
//  6 days ahead through the shared `PaidBookingWindow`, the same rule as both
//  client pickers. A free booking is not capped. Slots past the limit stay
//  listed but cannot be selected.
//
//  Only `submitRefusesFarSlot` builds an API, and it is a stub that records any
//  request, so a regressed guard fails the test instead of reaching production.
//  Every other row never reaches the API.
//

import Foundation
import Testing
@testable import ClickMe2026

/// Counts stub requests from the `@Sendable` network handler.
private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }
}

@MainActor
@Suite("Expert reschedule window")
struct ExpertRescheduleWindowTests {

    private static let day: TimeInterval = 24 * 3600

    private static func slot(at offset: TimeInterval) -> BookingTimeSlot {
        BookingTimeSlot(startTime: Date().addingTimeInterval(offset), endTime: nil, isAvailable: true)
    }

    // MARK: - Paid flag

    @Test("a booking is paid when the consultation fee amount is above zero")
    func paidFlag() {
        #expect(ExpertRescheduleViewModel.isPaid(consultationFeeAmount: 45))
        #expect(ExpertRescheduleViewModel.isPaid(consultationFeeAmount: 0.5))
        #expect(!ExpertRescheduleViewModel.isPaid(consultationFeeAmount: 0))
    }

    // MARK: - Paid booking

    @Test("a paid booking's latest start is 6 days ahead")
    func paidLatestStart() throws {
        let viewModel = ExpertRescheduleViewModel(isPaidBooking: true)
        let latest = try #require(viewModel.latestBookableStart)
        let expected = Date().addingTimeInterval(PaidBookingWindow.maxLead)
        #expect(abs(latest.timeIntervalSince(expected)) < 1)
    }

    @Test("a paid slot just inside the limit is selectable, just past it is not")
    func paidEdge() {
        let viewModel = ExpertRescheduleViewModel(isPaidBooking: true)
        let near = Self.slot(at: PaidBookingWindow.maxLead - 60)
        let far = Self.slot(at: PaidBookingWindow.maxLead + 60)
        #expect(viewModel.isSelectableSlot(near))
        #expect(!viewModel.isSelectableSlot(far))
    }

    @Test("select(time:) refuses a far paid slot and accepts a near one")
    func selectGuard() {
        let viewModel = ExpertRescheduleViewModel(isPaidBooking: true)
        let near = Self.slot(at: 2 * Self.day)
        let far = Self.slot(at: 10 * Self.day)

        viewModel.select(time: far)
        #expect(viewModel.selectedTime == nil)

        viewModel.select(time: near)
        #expect(viewModel.selectedTime == near)
    }

    @Test("an unavailable or already started slot is never selectable")
    func unavailableOrPastSlot() {
        let viewModel = ExpertRescheduleViewModel(isPaidBooking: true)
        let taken = BookingTimeSlot(startTime: Date().addingTimeInterval(Self.day), endTime: nil, isAvailable: false)
        let past = BookingTimeSlot(startTime: Date().addingTimeInterval(-3600), endTime: nil, isAvailable: true)
        #expect(!viewModel.isSelectableSlot(taken))
        #expect(!viewModel.isSelectableSlot(past))
    }

    @Test("submit refuses a slot that drifted past the limit with the mapped copy and no request")
    func submitRefusesFarSlot() async {
        // A runtime-style view model (it has a booking id) with the paid flag
        // set through the seam. The API is a stub that counts requests and
        // answers with a transport error, so a regressed guard can neither reach
        // the live backend nor produce the mapped copy by accident.
        let requests = RequestCounter()
        let api = APITestFactory.make { _ in
            requests.increment()
            throw URLError(.notConnectedToInternet)
        }
        let viewModel = ExpertRescheduleViewModel(bookingId: UUID(), isPaidBooking: true, api: api)
        viewModel.selectedTime = Self.slot(at: 10 * Self.day)

        var succeeded = false
        await viewModel.submit(onSuccess: { succeeded = true })

        #expect(!succeeded)
        #expect(requests.count == 0)
        #expect(!viewModel.isSubmitting)
        #expect(viewModel.submitError == BookingErrorMapper.message(for: .rescheduleTooFarAhead, fallback: ""))
        #expect(viewModel.submitError?.isEmpty == false)
    }

    // MARK: - Free booking

    @Test("a free booking is not capped")
    func freeBookingNotCapped() {
        let viewModel = ExpertRescheduleViewModel(isPaidBooking: false)
        #expect(viewModel.latestBookableStart == nil)

        let far = Self.slot(at: 30 * Self.day)
        #expect(viewModel.isBookableStart(far.startTime))
        #expect(viewModel.isSelectableSlot(far))
        viewModel.select(time: far)
        #expect(viewModel.selectedTime == far)
    }

    // MARK: - Runtime init

    @Test("the runtime view model is not capped before the detail loads")
    func runtimeDefaultsToUncapped() {
        let viewModel = ExpertRescheduleViewModel(bookingId: UUID())
        #expect(!viewModel.isPaidBooking)
        #expect(viewModel.latestBookableStart == nil)
        #expect(viewModel.isBookableStart(Date().addingTimeInterval(30 * Self.day)))
    }
}
