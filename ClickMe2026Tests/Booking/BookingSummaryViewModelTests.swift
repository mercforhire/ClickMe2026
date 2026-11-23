//
//  BookingSummaryViewModelTests.swift
//  ClickMe2026Tests
//
//  BOOK-06: Booking Summary answers an expert-proposed reschedule through the
//  shared `RescheduleResponder` (D-01) and updates in place (D-03).
//  Message Expert opens the chat through POST /chats/initiate (quick 261122-r2o).
//  The price row always shows, and a free session reads Session fee · Free (G-03-1-ITEM14).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Booking summary view model", .serialized)
@MainActor
struct BookingSummaryViewModelTests {

    private typealias Fixtures = ClientBookingFixtures

    private var bookingUUID: UUID { UUID(uuidString: Fixtures.bookingId)! }
    private var detailPath: String { "/client/bookings/" + Fixtures.bookingId }

    /// `GET /bookings/:id/reviews/context` success envelope, shaped like `ReviewContextData`.
    /// Plan 03-07 reuses this for its review-gate rows.
    nonisolated private static func reviewContextJSON(hasSubmitted: Bool) -> Data {
        let prefill = hasSubmitted ? #"{"rating":4,"comment":"Great","tags":null}"# : "null"
        return Data(#"""
        {"status":"success","data":{
          "has_submitted":\#(hasSubmitted),
          "review_target":{"id":"\#(Fixtures.expertId)","name":"Ada Lovelace","avatar_url":null,"role":"expert"},
          "session_topic":"Free chat",
          "prefill":\#(prefill)
        }}
        """#.utf8)
    }

    /// Serves one fixed detail payload and a `has_submitted: false` review context; 404s everything else.
    private func summaryAPI(detail: Data) -> ClickMeAPI {
        let path = detailPath
        let review = Self.reviewContextJSON(hasSubmitted: false)
        return APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if requestPath.hasSuffix("/reviews/context") {
                return Fixtures.response(for: request, body: review)
            }
            if requestPath.hasSuffix(path) {
                return Fixtures.response(for: request, body: detail)
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
    }

    private func pendingDetail(initiatedBy: String, authorizationExpiresAt: String = "null") -> Data {
        Fixtures.detailJSON(
            status: "pending_reschedule",
            reschedule: Fixtures.rescheduleJSON(initiatedBy: initiatedBy, note: "Can we move it?"),
            authorizationExpiresAt: authorizationExpiresAt
        )
    }

    private func acceptPosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/accept-reschedule") == true
        }
    }

    // MARK: Exposure

    @Test("an expert-initiated pending_reschedule detail exposes the proposal and the current start")
    func expertProposalIsExposed() async {
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: summaryAPI(detail: pendingDetail(initiatedBy: "expert")))
        await vm.load()
        #expect(vm.loadState == .loaded)
        #expect(vm.reschedule?.initiatedBy == .expert)
        #expect(vm.reschedule?.note == "Can we move it?")
        #expect(vm.currentStartTime != nil)
    }

    // MARK: Accept in place

    @Test("accept sends one POST, then the screen shows the confirmed booking without leaving .loaded")
    func acceptUpdatesInPlace() async {
        let path = detailPath
        let pending = pendingDetail(initiatedBy: "expert")
        let confirmed = Fixtures.detailJSON(status: "confirmed", reschedule: "null")
        let review = Self.reviewContextJSON(hasSubmitted: false)
        let api = APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if requestPath.hasSuffix("/accept-reschedule") {
                return Fixtures.response(for: request, body: Fixtures.successMessage)
            }
            if requestPath.hasSuffix("/reviews/context") {
                return Fixtures.response(for: request, body: review)
            }
            if requestPath.hasSuffix(path) {
                let accepted = MockURLProtocol.recordedRequests.contains {
                    $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/accept-reschedule") == true
                }
                return Fixtures.response(for: request, body: accepted ? confirmed : pending)
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: api)
        await vm.load()
        #expect(vm.reschedule != nil)

        await vm.responder.accept()

        #expect(acceptPosts().count == 1)
        #expect(vm.reschedule == nil)
        #expect(vm.loadState == .loaded)
        #expect(vm.responder.apiError == nil)
    }

    // MARK: Failed refetch after a 2xx (WR-01)

    /// First detail GET returns the expert's proposal, every later one a 500. Both answer
    /// POSTs succeed (the decline with `declineBody`) and the review context answers.
    /// Anything else is a 404.
    private func failingRefetchAPI(declineBody: Data = Fixtures.successMessage) -> ClickMeAPI {
        let path = detailPath
        let pending = pendingDetail(initiatedBy: "expert")
        let review = Self.reviewContextJSON(hasSubmitted: false)
        return APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if request.httpMethod == "POST", requestPath.hasSuffix("/decline-reschedule") {
                return Fixtures.response(for: request, body: declineBody)
            }
            if request.httpMethod == "POST", requestPath.hasSuffix("/accept-reschedule") {
                return Fixtures.response(for: request, body: Fixtures.successMessage)
            }
            if requestPath.hasSuffix("/reviews/context") {
                return Fixtures.response(for: request, body: review)
            }
            if request.httpMethod == "GET", requestPath.hasSuffix(path) {
                let detailGets = MockURLProtocol.recordedRequests.filter {
                    $0.httpMethod == "GET" && $0.url?.path.hasSuffix(path) == true
                }
                if detailGets.count == 1 {
                    return Fixtures.response(for: request, body: pending)
                }
                return Fixtures.response(for: request, status: 500, body: Fixtures.errorBody(code: "INTERNAL"))
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
    }

    private func detailGetCount() -> Int {
        let path = detailPath
        return MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "GET" && $0.url?.path.hasSuffix(path) == true
        }.count
    }

    private func declinePosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/decline-reschedule") == true
        }
    }

    @Test("accept whose follow-up detail GETs return 500 clears the card and moves to the new time")
    func acceptWithFailedRefetchClearsCard() async {
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: failingRefetchAPI())
        vm.refetchRetryDelay = .milliseconds(1)
        await vm.load()
        #expect(vm.reschedule != nil)
        let proposedStart = Fixtures.defaultStart.addingTimeInterval(86_400)
        let oldDateTime = vm.dateTime

        await vm.responder.accept()

        #expect(acceptPosts().count == 1)
        // The refetch and its single retry both ran and both failed (WR-08).
        #expect(detailGetCount() == 3)
        #expect(vm.reschedule == nil)
        // WR-08: the old time must not outlive the accept.
        #expect(vm.dateTime != oldDateTime)
        #expect(abs((vm.currentStartTime ?? .distantPast).timeIntervalSince(proposedStart)) < 1)
        #expect(vm.loadState == .loaded)
        #expect(vm.responder.apiError == nil)
    }

    @Test("decline whose follow-up detail GETs return 500 still clears the card and keeps the time")
    func declineWithFailedRefetchClearsCard() async {
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: failingRefetchAPI())
        vm.refetchRetryDelay = .milliseconds(1)
        await vm.load()
        #expect(vm.reschedule != nil)
        let oldDateTime = vm.dateTime

        await vm.responder.decline(reason: "No")

        #expect(declinePosts().count == 1)
        #expect(detailGetCount() == 3)
        #expect(vm.reschedule == nil)
        #expect(vm.dateTime == oldDateTime)
        #expect(vm.loadState == .loaded)
        #expect(vm.responder.apiError == nil)
    }

    @Test("decline returning completed shows the Completed badge and keeps the time (T-03-23)")
    func declineAppliesReturnedStatus() async {
        let api = failingRefetchAPI(declineBody: Fixtures.declineSuccess(restored: "completed"))
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: api)
        vm.refetchRetryDelay = .milliseconds(1)
        await vm.load()
        let oldDateTime = vm.dateTime

        await vm.responder.decline(reason: "No")

        #expect(detailGetCount() == 3)
        #expect(vm.status == .completed)
        #expect(vm.dateTime == oldDateTime)
        #expect(vm.reschedule == nil)
        #expect(vm.responder.apiError == nil)
    }

    @Test("decline with no data in the body leaves the badge as it was and still clears the card")
    func declineWithoutStatusLeavesBadge() async {
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: failingRefetchAPI())
        vm.refetchRetryDelay = .milliseconds(1)
        await vm.load()
        // A pending_reschedule detail has no summary badge.
        #expect(vm.status == nil)

        await vm.responder.decline(reason: "No")

        #expect(vm.status == nil)
        #expect(vm.reschedule == nil)
        #expect(vm.responder.apiError == nil)
    }

    // MARK: Dialog copy

    @Test("the accept dialog message is the shared responder's, including the payment-conversion disclosure")
    func dialogMessageIsTheRespondersOwn() async {
        // The hold expires before the proposed end, so accepting converts the payment.
        let expiry = "\"" + Fixtures.iso(Fixtures.defaultStart.addingTimeInterval(3 * 3600)) + "\""
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: summaryAPI(detail: pendingDetail(initiatedBy: "expert", authorizationExpiresAt: expiry))
        )
        await vm.load()

        let expected = RescheduleResponder.acceptDialogMessage(
            proposal: vm.reschedule,
            authorizationExpiresAt: vm.authorizationExpiresAt,
            now: Date()
        )
        #expect(vm.acceptDialogMessage == expected)
        #expect(vm.acceptDialogMessage.contains("Your card hold will be released."))
    }

    // MARK: Silent refresh

    /// Serves `first` for the first detail GET and `later` (or a 500 when `nil`) for every later one.
    /// The review context answers once with `has_submitted: true`, then fails with a 500 when `reviewFailsAfterFirst`.
    private func refreshAPI(first: Data, later: Data?, reviewFailsAfterFirst: Bool = false) -> ClickMeAPI {
        let path = detailPath
        let review = Self.reviewContextJSON(hasSubmitted: true)
        return APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if requestPath.hasSuffix("/reviews/context") {
                let reviewRequests = MockURLProtocol.recordedRequests.filter {
                    $0.url?.path.hasSuffix("/reviews/context") == true
                }
                if reviewFailsAfterFirst, reviewRequests.count > 1 {
                    return Fixtures.response(for: request, status: 500, body: Fixtures.errorBody(code: "INTERNAL"))
                }
                return Fixtures.response(for: request, body: review)
            }
            if requestPath.hasSuffix(path) {
                let detailRequests = MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix(path) == true }
                if detailRequests.count == 1 {
                    return Fixtures.response(for: request, body: first)
                }
                if let later {
                    return Fixtures.response(for: request, body: later)
                }
                return Fixtures.response(for: request, status: 500, body: Fixtures.errorBody(code: "INTERNAL"))
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
    }

    @Test("a refresh whose detail GET fails after a successful load keeps the content and .loaded")
    func failedRefreshKeepsContent() async {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: refreshAPI(first: Fixtures.detailJSON(), later: nil)
        )
        await vm.load()
        #expect(vm.loadState == .loaded)
        let topic = vm.topic
        let expertName = vm.expertName
        #expect(topic == "Free chat")
        #expect(expertName == "Ada Lovelace")

        await vm.refresh()

        #expect(vm.loadState == .loaded)
        #expect(vm.topic == topic)
        #expect(vm.expertName == expertName)
    }

    @Test("a refresh whose detail succeeds but review context fails keeps .loaded, the new detail and the old review state")
    func failedReviewContextKeepsLoadedAndAppliesDetail() async {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: refreshAPI(
                first: Fixtures.detailJSON(),
                later: pendingDetail(initiatedBy: "expert"),
                reviewFailsAfterFirst: true
            )
        )
        await vm.load()
        #expect(vm.reschedule == nil)
        #expect(vm.hasSubmittedReview == true)

        await vm.refresh()

        #expect(vm.loadState == .loaded)
        #expect(vm.reschedule?.initiatedBy == .expert)
        #expect(vm.hasSubmittedReview == true)
    }

    // MARK: Leave a Review gate and booking ID (BOOK-17, BOOK-20)

    /// Serves a detail with `status` and a review context with the given `has_submitted`.
    private func loadedModel(status: String, hasSubmitted: Bool) async -> BookingSummaryViewModel {
        let path = detailPath
        let detail = Fixtures.detailJSON(status: status)
        let review = Self.reviewContextJSON(hasSubmitted: hasSubmitted)
        let api = APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if requestPath.hasSuffix("/reviews/context") {
                return Fixtures.response(for: request, body: review)
            }
            if requestPath.hasSuffix(path) {
                return Fixtures.response(for: request, body: detail)
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: api)
        await vm.load()
        return vm
    }

    @Test("a completed booking with no review offers Leave a Review")
    func completedWithoutReviewOffersReview() async {
        let vm = await loadedModel(status: "completed", hasSubmitted: false)
        #expect(vm.loadState == .loaded)
        #expect(vm.showsLeaveReview)
    }

    @Test("a completed booking with a submitted review does not offer Leave a Review")
    func completedWithReviewHidesReview() async {
        let vm = await loadedModel(status: "completed", hasSubmitted: true)
        #expect(vm.hasSubmittedReview)
        #expect(!vm.showsLeaveReview)
    }

    @Test(
        "a session that did not happen never offers Leave a Review",
        arguments: ["cancelled", "declined", "missed", "expired"]
    )
    func sessionThatDidNotHappenHidesReview(status: String) async {
        let vm = await loadedModel(status: status, hasSubmitted: false)
        #expect(vm.loadState == .loaded)
        #expect(!vm.showsLeaveReview)
    }

    @Test("Leave a Review is hidden before the detail loads, when the status is unknown")
    func reviewHiddenBeforeLoad() {
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: summaryAPI(detail: Fixtures.detailJSON()))
        #expect(vm.status == nil)
        #expect(!vm.showsLeaveReview)
    }

    @Test("the booking ID label is the shared BookingShortID format once loaded")
    func bookingIDLabelUsesSharedFormat() async {
        let vm = await loadedModel(status: "completed", hasSubmitted: false)
        #expect(vm.bookingIDLabel == BookingShortID.label(bookingUUID))
        #expect(vm.bookingIDLabel == "ID: #11111111")
    }

    // MARK: Decline note (BACK-02)

    private func declineModel(status: String, extraFields: String) async -> BookingSummaryViewModel {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: summaryAPI(detail: Fixtures.detailJSON(status: status, extraFields: extraFields))
        )
        await vm.load()
        return vm
    }

    @Test("a declined detail exposes the reason line and the expert's note, and keeps the Cancelled badge")
    func declinedDetailExposesNote() async {
        let vm = await declineModel(
            status: "declined",
            extraFields: #""decline_reason_code":"PRICING","decline_reason_text":"Too low""#
        )
        #expect(vm.declineNote == DeclineNote(reasonLine: "Pricing mismatch", text: "Too low"))
        #expect(vm.status == .cancelled)
    }

    @Test("a declined detail with neither code nor text shows no decline note")
    func declinedWithoutNoteShowsNothing() async {
        let vm = await declineModel(
            status: "declined",
            extraFields: #""decline_reason_code":null,"decline_reason_text":null"#
        )
        #expect(vm.loadState == .loaded)
        #expect(vm.declineNote == nil)
    }

    @Test("a cancelled detail never shows a decline note")
    func cancelledShowsNoDeclineNote() async {
        let vm = await declineModel(
            status: "cancelled",
            extraFields: #""decline_reason_code":"PRICING","decline_reason_text":"Too low""#
        )
        #expect(vm.declineNote == nil)
    }

    // MARK: Price row (G-03-1-ITEM14)

    private func priceModel(detail: Data) async -> BookingSummaryViewModel {
        let vm = BookingSummaryViewModel(bookingId: bookingUUID, api: summaryAPI(detail: detail))
        await vm.load()
        return vm
    }

    @Test("a free session shows the price row as Session fee · Free, and nothing before the load")
    func freeSessionShowsFree() async {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: summaryAPI(detail: Fixtures.detailJSON(status: "completed"))
        )
        #expect(vm.price == nil)

        await vm.load()

        #expect(vm.price == .free)
        #expect(vm.price?.text == "Free")
        #expect(vm.price?.label == "Session fee")
    }

    @Test("is_free true wins even when the detail also carries a price")
    func freeFlagWinsOverPrice() async {
        let vm = await priceModel(detail: Fixtures.detailJSON(
            status: "completed",
            isFree: true,
            priceAmount: 4500,
            currency: "CAD"
        ))

        #expect(vm.price == .free)
        #expect(vm.price?.text == "Free")
        #expect(vm.price?.label == "Session fee")
    }

    @Test("a paid session still shows PAID with the exact amount, cents kept")
    func paidSessionShowsAmount() async {
        let vm = await priceModel(detail: Fixtures.detailJSON(
            status: "completed",
            paymentStatus: "captured",
            isFree: false,
            priceAmount: 4550,
            currency: "CAD"
        ))

        #expect(vm.price == .paid("CA$45.50"))
        #expect(vm.price?.text == Money.format(minorUnits: 4550, currency: "CAD"))
        #expect(vm.price?.label == "PAID")
    }

    @Test("a paid topic with no price shows PAID with a dash, never an invented amount")
    func paidWithoutPriceShowsDash() async {
        let vm = await priceModel(detail: Fixtures.detailJSON(
            status: "completed",
            paymentStatus: "captured",
            isFree: false
        ))

        #expect(vm.price == .unknown)
        #expect(vm.price?.text == "\u{2014}")
        #expect(vm.price?.label == "PAID")
    }

    // MARK: Message Expert (quick 261122-r2o)

    nonisolated private static let threadId = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"

    nonisolated private static var initiateSuccess: Data {
        Data(#"{"status":"success","data":{"thread_id":"\#(threadId)","created_at":null}}"#.utf8)
    }

    private func initiatePosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/chats/initiate") == true
        }
    }

    /// Serves a cancelled booking's detail and review context, and hands every `POST /chats/initiate` to `onInitiate`.
    private func messageAPI(
        onInitiate: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> ClickMeAPI {
        let path = detailPath
        let detail = Fixtures.detailJSON(status: "cancelled")
        let review = Self.reviewContextJSON(hasSubmitted: false)
        return APITestFactory.make { request in
            let requestPath = request.url?.path ?? ""
            if request.httpMethod == "POST", requestPath.hasSuffix("/chats/initiate") {
                return try onInitiate(request)
            }
            if requestPath.hasSuffix("/reviews/context") {
                return Fixtures.response(for: request, body: review)
            }
            if requestPath.hasSuffix(path) {
                return Fixtures.response(for: request, body: detail)
            }
            return Fixtures.response(for: request, status: 404, body: Fixtures.errorBody(code: "NOT_FOUND"))
        }
    }

    @Test("Message Expert sends one POST /chats/initiate with the expert's peer_id and returns the thread")
    func messageExpertReturnsThread() async throws {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: messageAPI { request in
                Fixtures.response(for: request, status: 201, body: Self.initiateSuccess)
            }
        )
        await vm.load()

        let thread = await vm.startChat()

        #expect(thread == UUID(uuidString: Self.threadId))
        #expect(vm.apiError == nil)
        #expect(!vm.isStartingChat)
        let posts = initiatePosts()
        #expect(posts.count == 1)
        let body = try #require(posts.first?.jsonBodyForTest())
        #expect((body["peer_id"] as? String)?.lowercased() == Fixtures.expertId)
    }

    @Test("Message Expert shows the server's message when the request fails")
    func messageExpertServerError() async {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: messageAPI { request in
                Fixtures.response(
                    for: request,
                    status: 500,
                    body: Fixtures.errorBody(code: "INTERNAL_ERROR", message: "Server exploded")
                )
            }
        )
        await vm.load()

        let thread = await vm.startChat()

        #expect(thread == nil)
        #expect(vm.apiError == "Server exploded")
        #expect(!vm.isStartingChat)
    }

    @Test("Message Expert reads a 404 NOT_FOUND as an unavailable user")
    func messageExpertUnavailable() async {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: messageAPI { request in
                Fixtures.response(
                    for: request,
                    status: 404,
                    body: Fixtures.errorBody(code: "NOT_FOUND", message: "User not found.")
                )
            }
        )
        await vm.load()

        let thread = await vm.startChat()

        #expect(thread == nil)
        #expect(vm.apiError == ExpertProfileBlockViewModel.unavailableMessage)
    }

    @Test("a second Message Expert tap while the first request runs sends no second POST")
    func messageExpertIgnoresSecondTap() async {
        let gate = RequestGate()
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: messageAPI { request in
                gate.waitIfArmed()
                return Fixtures.response(for: request, status: 201, body: Self.initiateSuccess)
            }
        )
        await vm.load()

        gate.arm()
        let first = Task { await vm.startChat() }
        await waitUntil("the POST /chats/initiate") { initiatePosts().count == 1 }
        #expect(vm.isStartingChat)
        let second = await vm.startChat()
        #expect(second == nil)
        gate.open()

        let thread = await first.value
        #expect(thread == UUID(uuidString: Self.threadId))
        #expect(initiatePosts().count == 1)
        #expect(!vm.isStartingChat)
    }

    @Test("Message Expert before the detail loads sends nothing and shows no alert")
    func messageExpertWithoutExpertId() async {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: messageAPI { request in
                Fixtures.response(for: request, status: 201, body: Self.initiateSuccess)
            }
        )

        let thread = await vm.startChat()

        #expect(thread == nil)
        #expect(initiatePosts().isEmpty)
        #expect(vm.apiError == nil)
    }

    @Test("a cancelled Message Expert request returns nil with no alert")
    func messageExpertCancellationShowsNoAlert() async {
        let vm = BookingSummaryViewModel(
            bookingId: bookingUUID,
            api: messageAPI { _ in throw URLError(.cancelled) }
        )
        await vm.load()

        let thread = await vm.startChat()

        #expect(thread == nil)
        #expect(vm.apiError == nil)
        #expect(!vm.isStartingChat)
    }

    // MARK: Preview seam

    @Test("the preview init's responder records no request")
    func previewResponderSendsNothing() async {
        MockURLProtocol.reset()
        let vm = BookingSummaryViewModel()

        await vm.responder.accept()
        await vm.responder.decline(reason: "no")

        #expect(MockURLProtocol.recordedRequests.isEmpty)
        #expect(vm.responder.apiError == nil)
    }
}
