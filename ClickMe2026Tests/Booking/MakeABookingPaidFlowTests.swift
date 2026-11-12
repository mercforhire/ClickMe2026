//
//  MakeABookingPaidFlowTests.swift
//  ClickMe2026Tests
//
//  PAY-02 (D-03): a paid confirm whose outcome is unknown keeps the
//  PaymentIntent, the pm_ id and the booking attempt id, and sends the same
//  confirm again. Runs through the real view model with every request answered
//  by a mocked URLSession, so no real hold is ever placed.
//

import Foundation
import Testing
@testable import ClickMe2026

/// Counts the confirm calls and hands the scripted answer for each. The handler
/// runs on a URL loading thread, so the counter sits behind a lock.
private final class ConfirmScript: @unchecked Sendable {
    typealias Answer = @Sendable (Int, URLRequest) throws -> (HTTPURLResponse, Data)

    private let lock = NSLock()
    private var calls = 0
    private let answer: Answer

    init(_ answer: @escaping Answer) {
        self.answer = answer
    }

    func respond(to request: URLRequest) throws -> (HTTPURLResponse, Data) {
        lock.lock()
        calls += 1
        let number = calls
        lock.unlock()
        return try answer(number, request)
    }
}

private enum PaidFlowFixture {
    static let bookingId = UUID()
    static let intentId = "pi_test"
    static let paymentMethodId = "pm_test"

    static let paidTopic = BookingTopic(
        id: UUID(), title: "Paid session", durationMinutes: 30, description: nil,
        priceAmount: 5000, currency: "USD", isFree: false
    )

    nonisolated static func http(_ request: URLRequest, status: Int, body: Data) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, body)
    }

    nonisolated static func created(_ request: URLRequest) -> (HTTPURLResponse, Data) {
        let body = """
        {"status":"success","data":{"booking_id":"\(bookingId.uuidString.lowercased())",\
        "status":"pending_approval","message":"Request sent","estimated_confirmation_time":"24h"}}
        """
        return http(request, status: 201, body: Data(body.utf8))
    }

    nonisolated static func coded(_ request: URLRequest, status: Int, code: String) -> (HTTPURLResponse, Data) {
        let body = #"{"status":"error","code":"\#(code)","message":"server text"}"#
        return http(request, status: status, body: Data(body.utf8))
    }
}

@Suite("Make a Booking paid flow", .serialized)
@MainActor
struct MakeABookingPaidFlowTests {

    /// A view model on a paid topic with a slot 2 days out, a PaymentIntent
    /// already created, and zero retry delays.
    private func makeViewModel(_ answer: @escaping ConfirmScript.Answer) -> MakeABookingViewModel {
        MockURLProtocol.reset()
        let script = ConfirmScript(answer)
        let api = APITestFactory.make { request in try script.respond(to: request) }
        let viewModel = MakeABookingViewModel(
            expertName: "Ada Lovelace",
            expertTitle: "Engineer",
            expertImageURL: "",
            topics: [PaidFlowFixture.paidTopic],
            api: api
        )
        viewModel.selectedTopic = PaidFlowFixture.paidTopic
        viewModel.selectedTimeSlot = BookingTimeSlot(
            startTime: Date().addingTimeInterval(2 * 24 * 3600),
            endTime: nil,
            isAvailable: true
        )
        viewModel.paymentIntentId = PaidFlowFixture.intentId
        viewModel.confirmRetryPolicy = ConfirmRetryPolicy(delays: [.zero, .zero])
        return viewModel
    }

    /// Every POST /bookings/confirm the mock saw, in order.
    private func confirmRequests() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/bookings/confirm") == true }
    }

    /// Asserts that every confirm request carried the same PaymentIntent and card.
    private func expectSameIntentAndCard(_ requests: [URLRequest]) {
        for request in requests {
            let body = request.jsonBodyForTest()
            #expect(body?["payment_intent_id"] as? String == PaidFlowFixture.intentId)
            #expect(body?["stripe_payment_method_id"] as? String == PaidFlowFixture.paymentMethodId)
        }
    }

    @Test("A confirm that times out twice is retried with the same ids and lands on the booking")
    func timeoutsThenReplay() async {
        let viewModel = makeViewModel { number, request in
            if number <= 2 { throw URLError(.timedOut) }
            return PaidFlowFixture.created(request)
        }
        let attemptId = viewModel.bookingAttemptId

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.bookingAttemptId == attemptId)
        let requests = confirmRequests()
        #expect(requests.count == 3)
        expectSameIntentAndCard(requests)
    }

    @Test("A coded 409 SLOT_UNAVAILABLE is not retried and keeps the slot-taken copy")
    func slotUnavailableIsNotRetried() async {
        let viewModel = makeViewModel { _, request in
            PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(confirmRequests().count == 1)
        #expect(viewModel.bookingError == "That time slot was just taken. Please pick another.")
        #expect(viewModel.selectedTimeSlot == nil)
        #expect(viewModel.completedBookingId == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.paymentIntentId == nil)
    }
}
