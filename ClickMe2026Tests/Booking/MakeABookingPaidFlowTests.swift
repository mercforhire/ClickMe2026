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

    // MARK: Retries exhausted (alert)

    /// A view model whose first `failures` confirm calls time out and whose later calls return 201.
    private func makeViewModel(timingOut failures: Int) -> MakeABookingViewModel {
        makeViewModel { number, request in
            if number <= failures { throw URLError(.timedOut) }
            return PaidFlowFixture.created(request)
        }
    }

    @Test("Three unknown failures raise the confirm-unknown alert and keep every id")
    func retriesExhaustedRaisesAlert() async {
        let viewModel = makeViewModel(timingOut: 3)
        let attemptId = viewModel.bookingAttemptId

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(viewModel.paidFlowAlert == .confirmUnknown(paymentReference: "pi_test"))
        #expect(viewModel.paidStep == .confirming)
        #expect(viewModel.paymentIntentId == "pi_test")
        #expect(viewModel.confirmPaymentMethodId == "pm_test")
        #expect(viewModel.bookingAttemptId == attemptId)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.completedBookingId == nil)
        #expect(viewModel.isSubmitting)
        #expect(!viewModel.showsConfirmingStatus)
        #expect(confirmRequests().count == 3)
    }

    @Test("Try again sends the same confirm and lands on the booking")
    func tryAgainReplays() async {
        let viewModel = makeViewModel(timingOut: 3)
        let attemptId = viewModel.bookingAttemptId
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        await viewModel.retryConfirm()

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(viewModel.paidFlowAlert == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.bookingAttemptId == attemptId)
        let requests = confirmRequests()
        #expect(requests.count == 4)
        expectSameIntentAndCard(requests)
    }

    @Test("Try again clears the alert while the status line shows again")
    func tryAgainShowsStatusAgain() async {
        let viewModel = makeViewModel(timingOut: 99)
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(viewModel.paidFlowAlert != nil)

        // A second full cycle also ends unknown, so the alert comes back.
        await viewModel.retryConfirm()

        #expect(viewModel.paidFlowAlert == .confirmUnknown(paymentReference: "pi_test"))
        #expect(viewModel.paidStep == .confirming)
        #expect(confirmRequests().count == 6)
    }

    @Test("Not now resets the paid flow silently and keeps the form")
    func notNowResetsSilently() async {
        let viewModel = makeViewModel(timingOut: 3)
        let topic = viewModel.selectedTopic
        let slot = viewModel.selectedTimeSlot
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        viewModel.dismissConfirmAlert()

        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.paymentIntentId == nil)
        #expect(viewModel.confirmPaymentMethodId == nil)
        #expect(viewModel.paidFlowAlert == nil)
        #expect(viewModel.selectedTopic == topic)
        #expect(viewModel.selectedTimeSlot == slot)
        #expect(viewModel.bookingError == nil)
        #expect(!viewModel.isSubmitting)
    }

    @Test("While the alert is up, Book Now makes no request")
    func bookIsBlockedWhileAlertIsUp() async {
        let viewModel = makeViewModel(timingOut: 3)
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        let before = MockURLProtocol.recordedRequests.count

        viewModel.book()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(MockURLProtocol.recordedRequests.count == before)
        #expect(viewModel.paidFlowAlert != nil)
    }

    @Test("Try again does nothing without a stored card or outside Confirming")
    func retryConfirmGuards() async {
        let viewModel = makeViewModel(timingOut: 0)

        // No stored pm_ id and an idle flow.
        await viewModel.retryConfirm()
        #expect(MockURLProtocol.recordedRequests.isEmpty)

        // A stored pm_ id, but the flow is not on Confirming.
        viewModel.confirmPaymentMethodId = PaidFlowFixture.paymentMethodId
        await viewModel.retryConfirm()
        #expect(MockURLProtocol.recordedRequests.isEmpty)

        // On Confirming, but no stored pm_ id.
        viewModel.confirmPaymentMethodId = nil
        viewModel.paidStep = .confirming
        await viewModel.retryConfirm()
        #expect(MockURLProtocol.recordedRequests.isEmpty)
    }

    @Test("The alert message is the UI-SPEC sentence, plus the reference when there is one")
    func alertCopy() {
        let sentence = "Your request may already have been sent. Try again to check, "
            + "or look in My Bookings before booking again."

        let withReference = MakeABookingViewModel.PaidFlowAlert.confirmUnknown(paymentReference: "pi_test")
        #expect(withReference.title == "We couldn't confirm your booking")
        #expect(withReference.message == sentence + "\n\nPayment reference: pi_test")

        let withoutReference = MakeABookingViewModel.PaidFlowAlert.confirmUnknown(paymentReference: nil)
        #expect(withoutReference.message == sentence)
    }

    @Test("The status line shows only while a paid confirm runs and no alert is up")
    func statusLineVisibility() {
        let viewModel = makeViewModel(timingOut: 0)
        #expect(!viewModel.showsConfirmingStatus)

        viewModel.paidStep = .confirming
        #expect(viewModel.showsConfirmingStatus)

        viewModel.paidFlowAlert = .confirmUnknown(paymentReference: nil)
        #expect(!viewModel.showsConfirmingStatus)
    }
}
