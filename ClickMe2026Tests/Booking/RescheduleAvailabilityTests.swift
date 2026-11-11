//
//  RescheduleAvailabilityTests.swift
//  ClickMe2026Tests
//
//  BOOK-16: the client reschedule picker asks for availability with
//  exclude_booking_id set to the booking being moved, Make a Booking does not,
//  a sent request posts "Reschedule request sent" and returns once, and the
//  changed error copy names the real payment menu (Profile > Payment).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Reschedule availability and return", .serialized)
@MainActor
struct RescheduleAvailabilityTests {

    private typealias Fixtures = ClientBookingFixtures

    private var bookingUUID: UUID { UUID(uuidString: Fixtures.bookingId)! }
    private var expertUUID: UUID { UUID(uuidString: Fixtures.expertId)! }

    nonisolated private static let sentToast = "Reschedule request sent"

    nonisolated private static let outsideAuthWindowCopy =
        "This time is past the payment hold on your original booking. Choose a different time, or cancel this booking and book again. Cancelling releases the hold on your card, so you won't be charged."
    nonisolated private static let noSavedCardCopy =
        "Please add a payment method in Profile > Payment before rescheduling this session."
    nonisolated private static let unusableCardCopy =
        "The card on file can't be used for this reschedule. Please add a new payment method in Profile > Payment and try again."

    nonisolated private static let emptyVaultBody = Data(#"{"status":"success","data":{"payment_methods":[]}}"#.utf8)

    /// Two days out, so no clock-dependent branch (current slot, paid cap) fires.
    nonisolated private static func futureSlotStart() -> Date {
        Date().addingTimeInterval(2 * 24 * 3600)
    }

    nonisolated private static func availabilityBody(slotStart: Date) -> Data {
        let end = slotStart.addingTimeInterval(1800)
        return Data(#"""
        {"status":"success","data":{
          "expert_timezone":"UTC","client_timezone":"UTC","month":"2099-01",
          "days":[{"date":"2099-01-01","slots":[
            {"start_utc":"\#(Fixtures.iso(slotStart))","end_utc":"\#(Fixtures.iso(end))","available":true,"held":false}
          ]}]
        }}
        """#.utf8)
    }

    nonisolated private static func isAvailability(_ request: URLRequest) -> Bool {
        request.httpMethod == "GET" && request.url?.path.hasSuffix("/availability") == true
    }

    nonisolated private static func isReschedule(_ request: URLRequest) -> Bool {
        request.httpMethod == "PATCH" && request.url?.path.hasSuffix("/reschedule") == true
    }

    nonisolated private static func isVault(_ request: URLRequest) -> Bool {
        request.url?.path.hasSuffix("/me/payment-methods") == true
    }

    nonisolated private static func availabilityRequests() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isAvailability)
    }

    nonisolated private static func queryValue(_ name: String, in request: URLRequest) -> String? {
        guard let url = request.url,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return nil }
        return items.first(where: { $0.name == name })?.value
    }

    /// Answers the detail, availability, reschedule and vault calls a view model makes.
    /// - Parameter reschedule: How to answer `PATCH .../reschedule`.
    private func makeAPI(
        slotStart: Date,
        reschedule: @escaping @Sendable (URLRequest) -> (HTTPURLResponse, Data)
    ) -> ClickMeAPI {
        APITestFactory.make { request in
            if Self.isAvailability(request) {
                return Fixtures.response(for: request, body: Self.availabilityBody(slotStart: slotStart))
            }
            if Self.isReschedule(request) {
                return reschedule(request)
            }
            if Self.isVault(request) {
                return Fixtures.response(for: request, body: Self.emptyVaultBody)
            }
            return Fixtures.response(for: request, body: Fixtures.detailJSON(status: "confirmed"))
        }
    }

    /// A loaded view model with the slot at `slotStart` selected.
    private func loadedViewModel(
        api: ClickMeAPI,
        toasts: ToastCenter,
        slotStart: Date
    ) async -> RescheduleViewModel {
        let viewModel = RescheduleViewModel(bookingId: bookingUUID, api: api, toasts: toasts)
        await viewModel.load()
        viewModel.selectedTime = BookingTimeSlot(
            startTime: slotStart,
            endTime: slotStart.addingTimeInterval(1800),
            isAvailable: true
        )
        return viewModel
    }

    // MARK: - exclude_booking_id

    @Test("getExpertAvailability sends exclude_booking_id when a booking is given")
    func apiSendsExclude() async throws {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Self.availabilityBody(slotStart: Self.futureSlotStart()))
        }

        _ = try await api.getExpertAvailability(id: expertUUID, month: "2099-01", excludeBookingId: bookingUUID)

        let request = try #require(Self.availabilityRequests().first)
        #expect(Self.queryValue("exclude_booking_id", in: request) == bookingUUID.uuidString)
        #expect(Self.queryValue("month", in: request) == "2099-01")
    }

    @Test("getExpertAvailability without the argument sends no exclude_booking_id")
    func apiOmitsExclude() async throws {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Self.availabilityBody(slotStart: Self.futureSlotStart()))
        }

        _ = try await api.getExpertAvailability(id: expertUUID, month: "2099-01")

        let request = try #require(Self.availabilityRequests().first)
        #expect(Self.queryValue("exclude_booking_id", in: request) == nil)
        #expect(Self.queryValue("month", in: request) == "2099-01")
    }

    @Test("the reschedule picker asks for availability excluding the booking being moved")
    func loadExcludesOwnBooking() async throws {
        let slotStart = Self.futureSlotStart()
        let api = makeAPI(slotStart: slotStart) { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))

        let viewModel = RescheduleViewModel(bookingId: bookingUUID, api: api, toasts: toasts)
        await viewModel.load()

        let request = try #require(Self.availabilityRequests().first)
        #expect(Self.queryValue("exclude_booking_id", in: request) == bookingUUID.uuidString)
    }

    // MARK: - Request sent

    @Test("a sent request posts the toast and calls onSuccess once")
    func submitPostsToastAndReturns() async {
        let slotStart = Self.futureSlotStart()
        let api = makeAPI(slotStart: slotStart) { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let viewModel = await loadedViewModel(api: api, toasts: toasts, slotStart: slotStart)
        var successCount = 0
        var messageAtSuccess: String?

        await viewModel.submit(onSuccess: {
            successCount += 1
            messageAtSuccess = toasts.current?.message
        })

        #expect(successCount == 1)
        #expect(messageAtSuccess == Self.sentToast)
        #expect(toasts.current?.message == Self.sentToast)
        #expect(viewModel.submitError == nil)
        toasts.dismiss()
    }

    @Test("RESCHEDULE_OUTSIDE_AUTH_WINDOW shows the new copy, no toast and no return")
    func outsideAuthWindowShowsNoToast() async {
        let slotStart = Self.futureSlotStart()
        let api = makeAPI(slotStart: slotStart) { request in
            Fixtures.response(
                for: request,
                status: 422,
                body: Fixtures.errorBody(code: "RESCHEDULE_OUTSIDE_AUTH_WINDOW")
            )
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let viewModel = await loadedViewModel(api: api, toasts: toasts, slotStart: slotStart)
        var successCount = 0

        await viewModel.submit(onSuccess: { successCount += 1 })

        #expect(viewModel.submitError == Self.outsideAuthWindowCopy)
        #expect(toasts.current == nil)
        #expect(successCount == 0)
    }

    @Test("an empty vault after PAYMENT_METHOD_REQUIRED names Profile > Payment and posts no toast")
    func emptyVaultNamesProfilePayment() async {
        let slotStart = Self.futureSlotStart()
        let api = makeAPI(slotStart: slotStart) { request in
            Fixtures.response(
                for: request,
                status: 422,
                body: Fixtures.errorBody(code: "PAYMENT_METHOD_REQUIRED")
            )
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let viewModel = await loadedViewModel(api: api, toasts: toasts, slotStart: slotStart)
        var successCount = 0

        await viewModel.submit(onSuccess: { successCount += 1 })

        #expect(viewModel.submitError == Self.noSavedCardCopy)
        #expect(toasts.current == nil)
        #expect(successCount == 0)
    }

    // MARK: - Copy

    @Test("PAYMENT_METHOD_REQUIRED on a retry names Profile > Payment")
    func unusableCardCopyNamesProfilePayment() {
        let body = Fixtures.errorBody(code: "PAYMENT_METHOD_REQUIRED")
        let error = NetworkError.httpError(statusCode: 422, data: body)

        #expect(RescheduleViewModel.rescheduleErrorMessage(for: error) == Self.unusableCardCopy)
    }
}
