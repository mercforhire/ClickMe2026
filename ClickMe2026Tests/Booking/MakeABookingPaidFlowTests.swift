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

    nonisolated static func inProgress(_ request: URLRequest) -> (HTTPURLResponse, Data) {
        let body = """
        {"status":"error","code":"PAYMENT_IN_PROGRESS",\
        "message":"This payment is still being processed. Please try again in a moment."}
        """
        return http(request, status: 409, body: Data(body.utf8))
    }

    nonisolated static func duplicate(_ request: URLRequest, bookingId: String) -> (HTTPURLResponse, Data) {
        let body = """
        {"status":"error","code":"DUPLICATE_BOOKING","message":"You already have a booking for this time.",\
        "detail":{"booking_id":"\(bookingId)"}}
        """
        return http(request, status: 409, body: Data(body.utf8))
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
            ledger: UnconfirmedBookingLedger(),
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

    // MARK: 409 PAYMENT_IN_PROGRESS (D-17)

    /// A view model whose first `inProgress` confirm calls answer 409
    /// PAYMENT_IN_PROGRESS and whose later calls return 201.
    private func makeViewModel(inProgress: Int) -> MakeABookingViewModel {
        makeViewModel { number, request in
            if number <= inProgress {
                return PaidFlowFixture.inProgress(request)
            }
            return PaidFlowFixture.created(request)
        }
    }

    @Test("409 PAYMENT_IN_PROGRESS then 201 retries the same confirm and lands on the booking")
    func paymentInProgressThenReplay() async {
        let viewModel = makeViewModel(inProgress: 1)
        let attemptId = viewModel.bookingAttemptId

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.paidFlowAlert == nil)
        #expect(viewModel.bookingAttemptId == attemptId)
        let requests = confirmRequests()
        #expect(requests.count == 2)
        expectSameIntentAndCard(requests)
    }

    @Test("Three 409 PAYMENT_IN_PROGRESS answers raise the alert, never server copy, and keep every id")
    func paymentInProgressExhausted() async {
        let viewModel = makeViewModel(inProgress: 3)
        let attemptId = viewModel.bookingAttemptId

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(viewModel.paidFlowAlert == .confirmUnknown(paymentReference: "pi_test"))
        #expect(viewModel.paymentIntentId == "pi_test")
        #expect(viewModel.confirmPaymentMethodId == "pm_test")
        #expect(viewModel.paidStep == .confirming)
        #expect(viewModel.bookingAttemptId == attemptId)
        #expect(viewModel.bookingError == nil)
        #expect(confirmRequests().count == 3)

        await viewModel.retryConfirm()

        let requests = confirmRequests()
        #expect(requests.count == 4)
        expectSameIntentAndCard(requests)
        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(viewModel.bookingAttemptId == attemptId)
    }

    // MARK: Unconfirmed-booking ledger (D-04, D-15, D-17)

    /// The expert id and slot start the view model confirms for.
    private func ledgerKey(_ viewModel: MakeABookingViewModel) -> (expertId: UUID, start: Date) {
        (viewModel.expertId, viewModel.selectedTimeSlot?.startTime ?? .distantPast)
    }

    private func ledgerHolds(_ viewModel: MakeABookingViewModel, start: Date) -> Bool {
        viewModel.ledger.contains(expertId: viewModel.expertId, start: start)
    }

    @Test("Three unknown confirm failures leave the record, also after Not now")
    func unknownKeepsRecord() async {
        let viewModel = makeViewModel(timingOut: 3)
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(ledgerHolds(viewModel, start: start))

        viewModel.dismissConfirmAlert()
        #expect(ledgerHolds(viewModel, start: start))
    }

    @Test("Three 409 PAYMENT_IN_PROGRESS confirms leave the record, also after Not now (D-17)")
    func paymentInProgressKeepsRecord() async {
        let viewModel = makeViewModel(inProgress: 3)
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(viewModel.paidFlowAlert == .confirmUnknown(paymentReference: "pi_test"))
        #expect(ledgerHolds(viewModel, start: start))

        viewModel.dismissConfirmAlert()
        #expect(ledgerHolds(viewModel, start: start))
    }

    @Test("A 409 PAYMENT_IN_PROGRESS confirm followed by a 201 clears the record")
    func paymentInProgressThenCreatedClearsRecord() async {
        let viewModel = makeViewModel(inProgress: 1)
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(!ledgerHolds(viewModel, start: start))
    }

    @Test("A 201 confirm clears the record")
    func createdClearsRecord() async {
        let viewModel = makeViewModel { _, request in PaidFlowFixture.created(request) }
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(!ledgerHolds(viewModel, start: start))
    }

    @Test("A 422 INTENT_EXPIRED confirm clears the record")
    func intentExpiredClearsRecord() async {
        let viewModel = makeViewModel { _, request in
            PaidFlowFixture.coded(request, status: 422, code: "INTENT_EXPIRED")
        }
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(viewModel.bookingError != nil)
        #expect(!ledgerHolds(viewModel, start: start))
    }

    @Test("A 409 SLOT_UNAVAILABLE confirm keeps the record")
    func slotUnavailableKeepsRecord() async {
        let viewModel = makeViewModel { _, request in
            PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(ledgerHolds(viewModel, start: start))
    }

    /// Waits up to 3 s for the book() task to reach a result.
    private func bookAndWaitForOutcome(_ viewModel: MakeABookingViewModel) async {
        viewModel.book()
        for _ in 0 ..< 150 {
            if viewModel.completedBookingId != nil || viewModel.bookingError != nil { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    @Test("After a lost confirm, a DUPLICATE_BOOKING on the same slot opens that booking (D-15)")
    func duplicateRoutesToExistingBooking() async {
        let existing = UUID()
        let viewModel = makeViewModel { _, request in
            if request.url?.path.hasSuffix("/bookings/payment-intent") == true {
                return PaidFlowFixture.duplicate(request, bookingId: existing.uuidString.lowercased())
            }
            throw URLError(.timedOut)
        }
        let start = ledgerKey(viewModel).start
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        viewModel.dismissConfirmAlert()
        #expect(ledgerHolds(viewModel, start: start))
        let confirmsBefore = confirmRequests().count

        await bookAndWaitForOutcome(viewModel)

        #expect(viewModel.completedBookingId == existing)
        #expect(viewModel.paidFlowAlert == nil)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(!ledgerHolds(viewModel, start: start))
        #expect(confirmRequests().count == confirmsBefore)
    }
}
