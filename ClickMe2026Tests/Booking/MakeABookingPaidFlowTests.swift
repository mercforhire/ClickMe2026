//
//  MakeABookingPaidFlowTests.swift
//  ClickMe2026Tests
//
//  PAY-02 (D-03): a paid confirm whose outcome is unknown keeps the
//  PaymentIntent, the pm_ id and the booking attempt id, and sends the same
//  confirm again. Runs through the real view model with every request answered
//  by a mocked URLSession, so no real hold is ever placed.
//

import Combine
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

/// Numbers only the requests it is asked about, behind a lock (the handler runs
/// on a URL loading thread). Same shape as `ConfirmScript`.
private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0

    func next() -> Int {
        lock.lock(); defer { lock.unlock() }
        calls += 1
        return calls
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

    /// A second paid topic, used to change the form after the PaymentIntent exists (CR-01).
    static let otherPaidTopic = BookingTopic(
        id: UUID(), title: "Other paid session", durationMinutes: 45, description: nil,
        priceAmount: 7500, currency: "USD", isFree: false
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

    /// Bare 200 body of POST /bookings/payment-intent (no envelope).
    nonisolated static func intentCreated(_ request: URLRequest) -> (HTTPURLResponse, Data) {
        let body = """
        {"payment_intent_id":"pi_snap","client_secret":"pi_snap_secret","customer_id":"cus_test",\
        "ephemeral_key":"ek_test","total_amount":50,"currency":"USD",\
        "summary":{"subtotal":50,"discount":0,"total":50}}
        """
        return http(request, status: 200, body: Data(body.utf8))
    }

    /// 200 body of POST /me/payment-methods/setup-intent.
    nonisolated static func setupCreated(_ request: URLRequest) -> (HTTPURLResponse, Data) {
        let body = """
        {"status":"success","data":{"client_secret":"seti_test_secret_x","customer_id":"cus_test",\
        "ephemeral_key":"ek_test"}}
        """
        return http(request, status: 200, body: Data(body.utf8))
    }

    nonisolated static func coded(_ request: URLRequest, status: Int, code: String) -> (HTTPURLResponse, Data) {
        let body = #"{"status":"error","code":"\#(code)","message":"server text"}"#
        return http(request, status: status, body: Data(body.utf8))
    }
}

@Suite("Make a Booking paid flow", .serialized)
@MainActor
struct MakeABookingPaidFlowTests {

    /// A view model on a paid topic with a slot 2 days out, a paid attempt for
    /// that topic and slot already installed (pass `installingAttempt: false`
    /// to start without one), and zero retry delays.
    private func makeViewModel(
        installingAttempt: Bool = true,
        _ answer: @escaping ConfirmScript.Answer
    ) -> MakeABookingViewModel {
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
        let slot = BookingTimeSlot(
            startTime: Date().addingTimeInterval(2 * 24 * 3600),
            endTime: nil,
            isAvailable: true
        )
        viewModel.selectedTimeSlot = slot
        if installingAttempt {
            viewModel.installPaidAttemptForTesting(MakeABookingViewModel.PaidAttempt(
                topic: PaidFlowFixture.paidTopic,
                slot: slot,
                paymentIntentId: PaidFlowFixture.intentId,
                meetingType: viewModel.meetingType,
                clientNotes: nil
            ))
        }
        viewModel.confirmRetryPolicy = ConfirmRetryPolicy(delays: [.zero, .zero])
        return viewModel
    }

    /// Every POST /bookings/confirm the mock saw, in order.
    private func confirmRequests() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/bookings/confirm") == true }
    }

    /// A string field of one request body, nil when absent.
    private func bodyString(_ request: URLRequest, _ key: String) -> String? {
        request.jsonBodyForTest()?[key] as? String
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

    @Test("A coded 409 SLOT_UNAVAILABLE on confirm is not retried and shows the may-already-be-booked alert")
    func slotUnavailableIsNotRetried() async {
        let viewModel = makeViewModel { _, request in
            PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        await viewModel.finishAvailabilityLoad()

        // The confirm itself recorded the slot (D-04), so "taken" could be the
        // client's own booking and the plain copy must not be shown.
        #expect(confirmRequests().count == 1)
        #expect(viewModel.paidFlowAlert == .mayAlreadyBeBooked)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.selectedTimeSlot == nil)
        #expect(viewModel.completedBookingId == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.paymentIntentId == nil)
    }

    // MARK: A taken slot reloads the calendar (WR-14)

    private let freeTopic = BookingTopic(
        id: UUID(), title: "Free chat", durationMinutes: 30, description: nil,
        priceAmount: nil, currency: nil, isFree: true
    )

    @Test("A confirm 409 SLOT_UNAVAILABLE reloads the calendar and keeps it on screen while it loads")
    func confirmSlotUnavailableReloadsCalendar() async {
        let viewModel = makeViewModel { _, request in
            if request.url?.path.hasSuffix("/availability") == true { return Self.availabilityAnswer(request) }
            return PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }
        viewModel.availabilityState = .loaded
        var states: [LoadState] = []
        let sink = viewModel.$availabilityState.sink { states.append($0) }
        defer { sink.cancel() }

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        await viewModel.finishAvailabilityLoad()

        #expect(viewModel.selectedTimeSlot == nil)
        // The center month and its two neighbours.
        #expect(availabilityRequests().count == 3)
        #expect(viewModel.availabilityState == .loaded)
        #expect(!viewModel.availabilityByDate.isEmpty)
        #expect(!states.contains(.loading))
    }

    @Test("A payment-intent 409 SLOT_UNAVAILABLE reloads the calendar")
    func intentSlotUnavailableReloadsCalendar() async {
        let viewModel = makeViewModel(installingAttempt: false) { _, request in
            if request.url?.path.hasSuffix("/availability") == true { return Self.availabilityAnswer(request) }
            return PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }

        await bookAndWaitForOutcome(viewModel)

        #expect(viewModel.bookingError == slotTakenCopy)
        #expect(availabilityRequests().count == 3)
        #expect(viewModel.availabilityState == .loaded)
    }

    @Test("A free booking 409 SLOT_UNAVAILABLE clears the slot and reloads the calendar")
    func freeSlotUnavailableReloadsCalendar() async {
        let viewModel = makeViewModel(installingAttempt: false) { _, request in
            if request.url?.path.hasSuffix("/availability") == true { return Self.availabilityAnswer(request) }
            return PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }
        viewModel.selectedTopic = freeTopic
        #expect(viewModel.selectedTimeSlot != nil)

        await bookAndWaitForOutcome(viewModel)

        #expect(viewModel.bookingError == slotTakenCopy)
        #expect(viewModel.selectedTimeSlot == nil)
        #expect(availabilityRequests().count == 3)
        #expect(viewModel.availabilityState == .loaded)
    }

    @Test("A coded error other than SLOT_UNAVAILABLE does not reload the calendar")
    func otherCodedErrorDoesNotReloadCalendar() async {
        let viewModel = makeViewModel { _, request in
            PaidFlowFixture.coded(request, status: 422, code: "INTENT_EXPIRED")
        }

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        await viewModel.finishAvailabilityLoad()

        #expect(availabilityRequests().isEmpty)
    }

    @Test("The reload after SLOT_UNAVAILABLE shows the held slot as unavailable and leaves nothing selected")
    func reloadAfterTakenSlotShowsHeldSlotUnavailable() async throws {
        // The calendar still lists the slot, now held by someone else.
        let viewModel = makeViewModel(installingAttempt: false) { _, request in
            if request.url?.path.hasSuffix("/availability") == true {
                let month = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                    .queryItems?.first { $0.name == "month" }?.value ?? "2030-01"
                let body = """
                {"status":"success","data":{"expert_timezone":"UTC","client_timezone":"UTC","month":"\(month)",\
                "days":[{"date":"\(month)-15","slots":[{"start_utc":"\(month)-15T15:00:00.000Z",\
                "end_utc":"\(month)-15T15:30:00.000Z","available":false,"held":true}]}]}}
                """
                return PaidFlowFixture.http(request, status: 200, body: Data(body.utf8))
            }
            return PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }

        await bookAndWaitForOutcome(viewModel)

        #expect(viewModel.selectedTimeSlot == nil)
        let offered = viewModel.availabilityByDate.values.flatMap { $0 }
        #expect(!offered.isEmpty)
        #expect(offered.allSatisfy { !$0.isAvailable })
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

    @Test("Book Now snapshots the paid attempt, and a later form change never reaches the confirm (CR-01)")
    func bookCreatesPaidAttempt() async throws {
        let viewModel = makeViewModel(installingAttempt: false) { _, request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("/bookings/payment-intent") { return PaidFlowFixture.intentCreated(request) }
            if path.hasSuffix("/payment-methods/setup-intent") { return PaidFlowFixture.setupCreated(request) }
            return PaidFlowFixture.created(request)
        }
        let slot = try #require(viewModel.selectedTimeSlot)
        #expect(viewModel.paidAttempt == nil)

        viewModel.book()
        for _ in 0 ..< 150 where viewModel.paidStep != .collectingPaymentMethod {
            try? await Task.sleep(for: .milliseconds(20))
        }

        #expect(viewModel.paidStep == .collectingPaymentMethod)
        #expect(
            viewModel.paidAttempt == MakeABookingViewModel.PaidAttempt(
                topic: PaidFlowFixture.paidTopic,
                slot: slot,
                paymentIntentId: "pi_snap",
                meetingType: .inAppVoice,
                clientNotes: nil
            )
        )

        viewModel.selectedTopic = PaidFlowFixture.otherPaidTopic
        viewModel.selectedTimeSlot = BookingTimeSlot(
            startTime: slot.startTime.addingTimeInterval(3600),
            endTime: nil,
            isAvailable: true
        )
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        let requests = confirmRequests()
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        #expect(bodyString(request, "payment_intent_id") == "pi_snap")
        #expect(bodyString(request, "topic_id") == PaidFlowFixture.paidTopic.id.uuidString.lowercased())
        #expect(bodyString(request, "start_time") == formatter.string(from: slot.startTime))
        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
    }

    // MARK: Book Now locks the form at once and snapshots it (IN-16)

    /// Answers the two kick-off calls of a paid attempt and counts the PaymentIntent requests.
    private func makeKickOffViewModel() -> MakeABookingViewModel {
        makeViewModel(installingAttempt: false) { _, request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("/bookings/payment-intent") { return PaidFlowFixture.intentCreated(request) }
            if path.hasSuffix("/payment-methods/setup-intent") { return PaidFlowFixture.setupCreated(request) }
            if path.hasSuffix("/bookings/request") { return PaidFlowFixture.created(request) }
            return PaidFlowFixture.coded(request, status: 500, code: "INTERNAL")
        }
    }

    private func intentRequests() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/bookings/payment-intent") == true }
    }

    @Test("A second Book Now tap before the first one's task runs sends no second PaymentIntent request")
    func doubleTapSendsOnePaymentIntent() async {
        let viewModel = makeKickOffViewModel()

        viewModel.book()
        // The lock is on before any task body runs.
        #expect(viewModel.isSubmitting)
        viewModel.book()

        for _ in 0 ..< 150 where viewModel.paidStep != .collectingPaymentMethod {
            try? await Task.sleep(for: .milliseconds(20))
        }

        #expect(viewModel.paidStep == .collectingPaymentMethod)
        #expect(intentRequests().count == 1)
    }

    @Test("A second Book Now tap on a free topic sends one booking request")
    func doubleTapSendsOneFreeRequest() async {
        let viewModel = makeKickOffViewModel()
        viewModel.selectedTopic = freeTopic

        viewModel.book()
        #expect(viewModel.isSubmitting)
        viewModel.book()

        for _ in 0 ..< 150 where viewModel.completedBookingId == nil {
            try? await Task.sleep(for: .milliseconds(20))
        }

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        let requests = MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/bookings/request") == true }
        #expect(requests.count == 1)
        #expect(!viewModel.isSubmitting)
    }

    @Test("The attempt keeps the meeting type and notes Book Now saw, not what the form says after its awaits")
    func attemptKeepsBookNowFormValues() async {
        let viewModel = makeKickOffViewModel()
        viewModel.clientNotes = "  Please cover Swift concurrency  "

        viewModel.book()
        // Edits that land before the first request has answered.
        viewModel.clientNotes = "changed"
        viewModel.meetingType = .skypeZoom

        for _ in 0 ..< 150 where viewModel.paidStep != .collectingPaymentMethod {
            try? await Task.sleep(for: .milliseconds(20))
        }

        #expect(viewModel.paidAttempt?.clientNotes == "Please cover Swift concurrency")
        #expect(viewModel.paidAttempt?.meetingType == .inAppVoice)
    }

    @Test("paymentIntentId reads the attempt and a reset clears both")
    func paymentIntentIdFollowsAttempt() {
        let viewModel = makeViewModel(timingOut: 0)
        #expect(viewModel.paymentIntentId == viewModel.paidAttempt?.paymentIntentId)
        #expect(viewModel.paymentIntentId == PaidFlowFixture.intentId)

        viewModel.resetPaidFlow()

        #expect(viewModel.paidAttempt == nil)
        #expect(viewModel.paymentIntentId == nil)
    }

    @Test("Try again after the topic and slot changed still confirms the topic and slot that were paid for (CR-01)")
    func retryKeepsOriginalSelection() async throws {
        let viewModel = makeViewModel(timingOut: 3)
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        let first = try #require(confirmRequests().first?.jsonBodyForTest())
        let originalSlot = try #require(viewModel.selectedTimeSlot)

        viewModel.selectedTopic = PaidFlowFixture.otherPaidTopic
        viewModel.selectedTimeSlot = BookingTimeSlot(
            startTime: originalSlot.startTime.addingTimeInterval(3600),
            endTime: nil,
            isAvailable: true
        )
        await viewModel.retryConfirm()

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        let requests = confirmRequests()
        #expect(requests.count == 4)
        expectSameIntentAndCard(requests)
        for request in requests {
            let body = request.jsonBodyForTest()
            #expect(body?["start_time"] as? String == first["start_time"] as? String)
            #expect(body?["topic_id"] as? String == first["topic_id"] as? String)
            #expect(body?["meeting_type"] as? String == first["meeting_type"] as? String)
        }
        #expect(first["topic_id"] as? String == PaidFlowFixture.paidTopic.id.uuidString.lowercased())
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

    @Test(
        "A confirm that says the PaymentIntent is unusable ends the attempt and starts a new booking attempt",
        arguments: [
            (422, "INTENT_EXPIRED"),
            (409, "PI_CONTEXT_MISMATCH"),
            (409, "PI_AMOUNT_MISMATCH"),
            (409, "PI_CURRENCY_MISMATCH"),
        ]
    )
    func unusableIntentStartsNewAttempt(status: Int, code: String) async {
        let viewModel = makeViewModel { _, request in
            PaidFlowFixture.coded(request, status: status, code: code)
        }
        let attemptId = viewModel.bookingAttemptId
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        // One request: a coded answer is not retried.
        #expect(confirmRequests().count == 1)
        #expect(viewModel.bookingAttemptId != attemptId)
        #expect(viewModel.paidAttempt == nil)
        #expect(viewModel.confirmPaymentMethodId == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.bookingError?.contains("Payment reference") == false)
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
        await viewModel.finishAvailabilityLoad()

        #expect(ledgerHolds(viewModel, start: start))
    }

    /// Waits up to 3 s for the book() task to reach a result, then for the calendar reload a
    /// taken slot starts (WR-14), so no request outlives the test.
    private func bookAndWaitForOutcome(_ viewModel: MakeABookingViewModel) async {
        viewModel.book()
        for _ in 0 ..< 150 {
            if viewModel.completedBookingId != nil || viewModel.bookingError != nil { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        await viewModel.finishAvailabilityLoad()
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

    // MARK: "You may already have this booking" (D-04)

    /// A view model whose payment-intent call is answered by `answer`; a confirm
    /// is never expected, so any other request is a test failure.
    private func makeIntentViewModel(
        recording: Bool,
        _ answer: @escaping @Sendable (URLRequest) -> (HTTPURLResponse, Data)
    ) -> MakeABookingViewModel {
        let viewModel = makeViewModel { _, request in answer(request) }
        if recording, let start = viewModel.selectedTimeSlot?.startTime {
            viewModel.ledger.record(expertId: viewModel.expertId, start: start)
        }
        return viewModel
    }

    private let slotTakenCopy = "That time slot was just taken. Please pick another."

    @Test("With a record, a payment-intent 409 SLOT_UNAVAILABLE shows the may-already-be-booked alert")
    func intentSlotUnavailableWithRecord() async {
        let viewModel = makeIntentViewModel(recording: true) { request in
            PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }
        let start = ledgerKey(viewModel).start

        viewModel.book()
        for _ in 0 ..< 150 where viewModel.paidFlowAlert == nil && viewModel.bookingError == nil {
            try? await Task.sleep(for: .milliseconds(20))
        }
        await viewModel.finishAvailabilityLoad()

        #expect(viewModel.paidFlowAlert == .mayAlreadyBeBooked)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.selectedTimeSlot == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(ledgerHolds(viewModel, start: start))
    }

    @Test("With a record, a confirm 409 SLOT_UNAVAILABLE gives the same alert and keeps the record")
    func confirmSlotUnavailableWithRecord() async {
        let viewModel = makeIntentViewModel(recording: true) { request in
            PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }
        let start = ledgerKey(viewModel).start

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        await viewModel.finishAvailabilityLoad()

        #expect(viewModel.paidFlowAlert == .mayAlreadyBeBooked)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.selectedTimeSlot == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(ledgerHolds(viewModel, start: start))
    }

    @Test("With no record, a payment-intent 409 SLOT_UNAVAILABLE keeps the plain slot-taken copy")
    func intentSlotUnavailableWithoutRecord() async {
        let viewModel = makeIntentViewModel(recording: false) { request in
            PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }

        await bookAndWaitForOutcome(viewModel)

        #expect(viewModel.bookingError == slotTakenCopy)
        #expect(viewModel.paidFlowAlert == nil)
        #expect(viewModel.selectedTimeSlot == nil)
    }

    @Test("With no record, a DUPLICATE_BOOKING shows the alert and does not open the booking")
    func duplicateWithoutRecord() async {
        let viewModel = makeIntentViewModel(recording: false) { request in
            PaidFlowFixture.duplicate(request, bookingId: UUID().uuidString.lowercased())
        }

        viewModel.book()
        for _ in 0 ..< 150 where viewModel.paidFlowAlert == nil && viewModel.bookingError == nil {
            try? await Task.sleep(for: .milliseconds(20))
        }

        #expect(viewModel.paidFlowAlert == .mayAlreadyBeBooked)
        #expect(viewModel.completedBookingId == nil)
        #expect(viewModel.bookingError == nil)
        #expect(viewModel.selectedTimeSlot == nil)
        #expect(viewModel.paidStep == .idle)
    }

    @Test("A DUPLICATE_BOOKING whose booking_id is not a UUID shows the alert even with a record")
    func duplicateWithUnparseableId() async {
        let viewModel = makeIntentViewModel(recording: true) { request in
            PaidFlowFixture.duplicate(request, bookingId: "not-a-uuid")
        }

        viewModel.book()
        for _ in 0 ..< 150 where viewModel.paidFlowAlert == nil && viewModel.bookingError == nil {
            try? await Task.sleep(for: .milliseconds(20))
        }

        #expect(viewModel.paidFlowAlert == .mayAlreadyBeBooked)
        #expect(viewModel.completedBookingId == nil)
        #expect(viewModel.selectedTimeSlot == nil)
    }

    @Test("Another expert's slot never matches the record: a different slot gets the plain copy")
    func differentSlotDoesNotMatch() async {
        let viewModel = makeIntentViewModel(recording: false) { request in
            PaidFlowFixture.coded(request, status: 409, code: "SLOT_UNAVAILABLE")
        }
        // A record for the same expert, an hour away from the chosen slot.
        if let start = viewModel.selectedTimeSlot?.startTime {
            viewModel.ledger.record(expertId: viewModel.expertId, start: start.addingTimeInterval(3600))
            viewModel.ledger.record(expertId: UUID(), start: start)
        }

        await bookAndWaitForOutcome(viewModel)

        #expect(viewModel.bookingError == slotTakenCopy)
        #expect(viewModel.paidFlowAlert == nil)
    }

    @Test("The may-already-be-booked alert reads Couldn't book and points to My Bookings")
    func mayAlreadyBeBookedCopy() {
        let alert = MakeABookingViewModel.PaidFlowAlert.mayAlreadyBeBooked
        #expect(alert.title == "Couldn't book")
        #expect(alert.message == "You may already have this booking. Check My Bookings.")
    }

    @Test("Closing the may-already-be-booked alert clears it")
    func dismissMayAlreadyBeBooked() {
        let viewModel = makeViewModel(timingOut: 0)
        viewModel.paidFlowAlert = .mayAlreadyBeBooked

        viewModel.dismissMayAlreadyBeBookedAlert()

        #expect(viewModel.paidFlowAlert == nil)
    }

    // MARK: Paid attempt stays intact (CR-01)

    private func isoString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    /// Moves the form to another paid topic and a slot an hour later.
    private func changeForm(_ viewModel: MakeABookingViewModel) {
        let start = viewModel.selectedTimeSlot?.startTime ?? Date()
        viewModel.selectedTopic = PaidFlowFixture.otherPaidTopic
        viewModel.selectedTimeSlot = BookingTimeSlot(
            startTime: start.addingTimeInterval(3600),
            endTime: nil,
            isAvailable: true
        )
    }

    @Test("A calendar reload while a paid attempt is in flight keeps the slot, the ids and the booking attempt")
    func reloadDuringConfirmKeepsSlot() async throws {
        let confirms = CallCounter()
        let viewModel = makeViewModel { _, request in
            if request.url?.path.contains("/availability") == true {
                return PaidFlowFixture.coded(request, status: 500, code: "INTERNAL")
            }
            if confirms.next() <= 3 { throw URLError(.timedOut) }
            return PaidFlowFixture.created(request)
        }
        let slot = try #require(viewModel.selectedTimeSlot)
        let attemptId = viewModel.bookingAttemptId
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(viewModel.paidFlowAlert == .confirmUnknown(paymentReference: "pi_test"))

        await viewModel.loadAvailability(for: viewModel.displayedMonth)

        #expect(viewModel.selectedTimeSlot == slot)
        #expect(viewModel.bookingAttemptId == attemptId)
        #expect(viewModel.paymentIntentId == "pi_test")
        #expect(viewModel.confirmPaymentMethodId == "pm_test")

        await viewModel.retryConfirm()

        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        let requests = confirmRequests()
        #expect(requests.count == 4)
        expectSameIntentAndCard(requests)
        for request in requests {
            #expect(bodyString(request, "start_time") == isoString(slot.startTime))
        }
    }

    @Test("With no attempt in flight a reload of the same month keeps the selected slot")
    func idleReloadKeepsSlot() async throws {
        let viewModel = makeViewModel(installingAttempt: false) { _, request in
            PaidFlowFixture.coded(request, status: 500, code: "INTERNAL")
        }
        let slot = try #require(viewModel.selectedTimeSlot)
        let attemptId = viewModel.bookingAttemptId
        #expect(!viewModel.isSubmitting)

        await viewModel.loadAvailability(for: viewModel.displayedMonth)

        #expect(viewModel.selectedTimeSlot == slot)
        #expect(viewModel.bookingAttemptId == attemptId)
    }

    /// `/availability` answers a one-slot month; every other path answers 500 (payment methods then read as none).
    nonisolated private static func availabilityAnswer(_ request: URLRequest) -> (HTTPURLResponse, Data) {
        guard request.url?.path.hasSuffix("/availability") == true else {
            return PaidFlowFixture.coded(request, status: 500, code: "INTERNAL")
        }
        let month = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "month" }?.value ?? "2030-01"
        let body = """
        {"status":"success","data":{"expert_timezone":"UTC","client_timezone":"UTC","month":"\(month)",\
        "days":[{"date":"\(month)-15","slots":[{"start_utc":"\(month)-15T15:00:00.000Z",\
        "end_utc":"\(month)-15T15:30:00.000Z","available":true,"held":false}]}]}}
        """
        return PaidFlowFixture.http(request, status: 200, body: Data(body.utf8))
    }

    private func availabilityRequests() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/availability") == true }
    }

    /// Month navigation starts an unstructured load. Waits (10 ms steps, up to 3 s) until it
    /// has loaded, so it cannot send requests into the next test's handler.
    private func settleAvailability(_ viewModel: MakeABookingViewModel) async {
        for _ in 0 ..< 300 {
            if viewModel.availabilityState == .loaded { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("Coming back to Make a Booking keeps the chosen slot and the booking attempt (WR-10)")
    func reappearKeepsSlot() async throws {
        let viewModel = makeViewModel(installingAttempt: false) { _, request in Self.availabilityAnswer(request) }
        await viewModel.onAppear()
        guard case .loaded = viewModel.availabilityState else {
            Issue.record("expected the first appear to load the calendar, got \(viewModel.availabilityState)")
            return
        }
        let loadedRequests = availabilityRequests().count

        // The user picks a slot, opens Payment Methods and pops back.
        let slot = BookingTimeSlot(startTime: Date().addingTimeInterval(2 * 24 * 3600), endTime: nil, isAvailable: true)
        viewModel.selectedTimeSlot = slot
        let attemptId = viewModel.bookingAttemptId
        await viewModel.onAppear()

        #expect(viewModel.selectedTimeSlot == slot)
        #expect(viewModel.bookingAttemptId == attemptId)
        guard case .loaded = viewModel.availabilityState else {
            Issue.record("a reappear must not flip the calendar to \(viewModel.availabilityState)")
            return
        }
        #expect(availabilityRequests().count == loadedRequests)
    }

    @Test("A calendar that failed to load loads again on the next appear")
    func reappearRetriesFailedCalendar() async {
        let failing = CallCounter()
        let viewModel = makeViewModel(installingAttempt: false) { _, request in
            if request.url?.path.hasSuffix("/availability") == true, failing.next() == 1 {
                return PaidFlowFixture.coded(request, status: 500, code: "INTERNAL")
            }
            return Self.availabilityAnswer(request)
        }
        await viewModel.onAppear()
        guard case .failed = viewModel.availabilityState else {
            Issue.record("expected .failed, got \(viewModel.availabilityState)")
            return
        }

        await viewModel.onAppear()

        guard case .loaded = viewModel.availabilityState else {
            Issue.record("expected .loaded, got \(viewModel.availabilityState)")
            return
        }
    }

    @Test("Changing the month clears the chosen slot", arguments: [true, false])
    func monthChangeClearsSlot(forward: Bool) async {
        let viewModel = makeViewModel(installingAttempt: false) { _, request in Self.availabilityAnswer(request) }
        #expect(viewModel.selectedTimeSlot != nil)

        if forward { viewModel.goToNextMonth() } else { viewModel.goToPreviousMonth() }

        #expect(viewModel.selectedTimeSlot == nil)
        await settleAvailability(viewModel)
    }

    @Test("A month change while a paid attempt is in flight keeps the slot")
    func monthChangeKeepsSlotDuringAttempt() async throws {
        let viewModel = makeViewModel { _, request in Self.availabilityAnswer(request) }
        let slot = try #require(viewModel.selectedTimeSlot)
        viewModel.paidStep = .confirming
        #expect(viewModel.isSubmitting)

        viewModel.goToNextMonth()

        #expect(viewModel.selectedTimeSlot == slot)
        await settleAvailability(viewModel)
    }

    @Test("The 3DS retry sends the topic and slot the payment was made for")
    func scaRetryKeepsOriginalSelection() async throws {
        let body402 = """
        {"status":"error","code":"PAYMENT_REQUIRES_ACTION","message":"Authentication required.",\
        "detail":{"client_secret":"pi_test_secret_sca","stripe_account":"acct_test"}}
        """
        let viewModel = makeViewModel { number, request in
            if number == 1 { return PaidFlowFixture.http(request, status: 402, body: Data(body402.utf8)) }
            return PaidFlowFixture.created(request)
        }
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(viewModel.pendingSCAChallenge != nil)
        #expect(viewModel.paidStep == .confirming)

        // CR-03: the card survives the 402, so the retry can resend it.
        #expect(viewModel.confirmPaymentMethodId == PaidFlowFixture.paymentMethodId)

        changeForm(viewModel)
        await viewModel.retryConfirmAfterSCA()

        let requests = confirmRequests()
        #expect(requests.count == 2)
        let first = try #require(requests.first)
        let second = try #require(requests.last)
        #expect(bodyString(second, "start_time") == bodyString(first, "start_time"))
        #expect(bodyString(second, "topic_id") == bodyString(first, "topic_id"))
        #expect(bodyString(second, "topic_id") == PaidFlowFixture.paidTopic.id.uuidString.lowercased())
        #expect(bodyString(second, "payment_intent_id") == PaidFlowFixture.intentId)
        // CR-03: the platform `pm_` the client chose, never the connected-account
        // clone id the Stripe SDK returns after the challenge.
        #expect(bodyString(second, "stripe_payment_method_id") == PaidFlowFixture.paymentMethodId)
        #expect(bodyString(second, "stripe_payment_method_id") == bodyString(first, "stripe_payment_method_id"))
        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(viewModel.confirmPaymentMethodId == nil)
    }

    @Test("A 3DS retry with no card left ends the attempt and sends no second confirm")
    func scaRetryWithoutCardCancels() async {
        let body402 = """
        {"status":"error","code":"PAYMENT_REQUIRES_ACTION","message":"Authentication required.",\
        "detail":{"client_secret":"pi_test_secret_sca","stripe_account":"acct_test"}}
        """
        let viewModel = makeViewModel { _, request in
            PaidFlowFixture.http(request, status: 402, body: Data(body402.utf8))
        }
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(viewModel.pendingSCAChallenge != nil)
        viewModel.confirmPaymentMethodId = nil

        await viewModel.retryConfirmAfterSCA()

        #expect(confirmRequests().count == 1)
        #expect(viewModel.pendingSCAChallenge == nil)
        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.bookingError != nil)
    }

    @Test("The unconfirmed-booking record stays on the attempt's slot when the form changes")
    func ledgerKeysOnPaidAttempt() async throws {
        let viewModel = makeViewModel(timingOut: 3)
        let original = try #require(viewModel.selectedTimeSlot).startTime
        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        changeForm(viewModel)
        let moved = try #require(viewModel.selectedTimeSlot).startTime

        #expect(ledgerHolds(viewModel, start: original))
        #expect(!ledgerHolds(viewModel, start: moved))

        viewModel.dismissConfirmAlert()

        #expect(ledgerHolds(viewModel, start: original))
        #expect(!ledgerHolds(viewModel, start: moved))
    }

    @Test("A confirm with no paid attempt makes no request and leaves the flow idle")
    func confirmWithoutAttemptMakesNoRequest() async {
        let viewModel = makeViewModel(installingAttempt: false) { _, request in
            PaidFlowFixture.created(request)
        }

        await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)

        #expect(MockURLProtocol.recordedRequests.isEmpty)
        #expect(viewModel.paidStep == .idle)
        #expect(viewModel.completedBookingId == nil)
    }

    @Test("Every way out of a paid attempt unlocks the form")
    func everyResetUnlocksTheForm() async {
        // The payment sheet is closed.
        let cancelled = makeViewModel(timingOut: 0)
        cancelled.paidStep = .collectingPaymentMethod
        #expect(cancelled.isSubmitting)
        cancelled.cancelPaidBooking()
        #expect(!cancelled.isSubmitting)
        #expect(cancelled.paidAttempt == nil)

        // The 3DS sheet is closed.
        let scaCancelled = makeViewModel(timingOut: 0)
        scaCancelled.paidStep = .collectingPaymentMethod
        #expect(scaCancelled.isSubmitting)
        scaCancelled.cancelSCA(withMessage: nil)
        #expect(!scaCancelled.isSubmitting)
        #expect(scaCancelled.paidAttempt == nil)

        // Not now on the confirm-unknown alert.
        let dismissed = makeViewModel(timingOut: 3)
        await dismissed.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(dismissed.isSubmitting)
        dismissed.dismissConfirmAlert()
        #expect(!dismissed.isSubmitting)
        #expect(dismissed.paidAttempt == nil)

        // A coded confirm error.
        let expired = makeViewModel { _, request in
            PaidFlowFixture.coded(request, status: 422, code: "INTENT_EXPIRED")
        }
        await expired.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId)
        #expect(!expired.isSubmitting)
        #expect(expired.paidAttempt == nil)
    }

    /// A view model whose first confirm times out and whose second answers 201,
    /// with its first confirm running (one request recorded, `isConfirmRunning`)
    /// and waiting 500 ms before the automatic retry. The handler is never
    /// blocked: the wait is the retry delay, a `Task.sleep` on the main actor.
    private func startSlowConfirm() async throws -> (MakeABookingViewModel, Task<Void, Never>) {
        let viewModel = makeViewModel(timingOut: 1)
        viewModel.confirmRetryPolicy = ConfirmRetryPolicy(delays: [.milliseconds(500), .zero])
        let run = Task { await viewModel.completePaidBooking(paymentMethodId: PaidFlowFixture.paymentMethodId) }
        for _ in 0 ..< 150 where !(confirmRequests().count == 1 && viewModel.isConfirmRunning) {
            try? await Task.sleep(for: .milliseconds(20))
        }
        try #require(confirmRequests().count == 1)
        try #require(viewModel.isConfirmRunning)
        return (viewModel, run)
    }

    @Test("A form edit while a confirm runs changes nothing the confirm or its retry sends")
    func formEditWhileConfirmRunsKeepsRequest() async throws {
        let (viewModel, run) = try await startSlowConfirm()
        let slot = try #require(viewModel.selectedTimeSlot)

        changeForm(viewModel)
        try #require(confirmRequests().count == 1)

        await run.value

        let requests = confirmRequests()
        #expect(requests.count == 2)
        expectSameIntentAndCard(requests)
        for request in requests {
            #expect(bodyString(request, "topic_id") == PaidFlowFixture.paidTopic.id.uuidString.lowercased())
            #expect(bodyString(request, "start_time") == isoString(slot.startTime))
            #expect(bodyString(request, "meeting_type") == MeetingType.inAppVoice.rawValue)
        }
        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
    }

    @Test("A second confirm cannot start while one runs")
    func secondConfirmWhileRunningIsRejected() async throws {
        let (viewModel, run) = try await startSlowConfirm()

        await viewModel.retryConfirm()
        await viewModel.completePaidBooking(paymentMethodId: "pm_other")

        #expect(confirmRequests().count == 1)
        #expect(viewModel.confirmPaymentMethodId == PaidFlowFixture.paymentMethodId)

        await run.value

        let requests = confirmRequests()
        #expect(requests.count == 2)
        expectSameIntentAndCard(requests)
        #expect(viewModel.completedBookingId == PaidFlowFixture.bookingId)
        #expect(!viewModel.isConfirmRunning)
    }
}
