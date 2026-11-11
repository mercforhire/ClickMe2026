//
//  BookingSummaryViewModelTests.swift
//  ClickMe2026Tests
//
//  BOOK-06: Booking Summary answers an expert-proposed reschedule through the
//  shared `RescheduleResponder` (D-01) and updates in place (D-03).
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
