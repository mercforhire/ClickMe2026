//
//  RescheduleResponderTests.swift
//  ClickMe2026Tests
//
//  BOOK-06: the shared accept / decline logic behind the reschedule response
//  card, including the PAYMENT_METHOD_REQUIRED recovery matrix, the 500-unit
//  decline cap and the accept dialog text.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Reschedule responder", .serialized)
@MainActor
struct RescheduleResponderTests {

    private typealias Fixtures = ClientBookingFixtures

    private var bookingUUID: UUID { UUID(uuidString: Fixtures.bookingId)! }

    nonisolated private static let vaultBody = Data(#"""
    {"status":"success","data":{"payment_methods":[
      {"id":"pm_other","brand":"visa","last4":"1111","exp_month":12,"exp_year":2030,"is_default":false},
      {"id":"pm_default","brand":"visa","last4":"4242","exp_month":12,"exp_year":2030,"is_default":true}
    ]}}
    """#.utf8)

    nonisolated private static let emptyVaultBody = Data(#"{"status":"success","data":{"payment_methods":[]}}"#.utf8)

    nonisolated private static func isAccept(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/accept-reschedule") == true
    }

    nonisolated private static func isDecline(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/decline-reschedule") == true
    }

    nonisolated private static func isVault(_ request: URLRequest) -> Bool {
        request.url?.path.hasSuffix("/me/payment-methods") == true
    }

    nonisolated private static func acceptPosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isAccept)
    }

    nonisolated private static func declinePosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isDecline)
    }

    /// A responder with a counting `refetch`.
    private func makeResponder(
        api: ClickMeAPI,
        refetchCount: RefetchCounter
    ) -> RescheduleResponder {
        let responder = RescheduleResponder(bookingId: bookingUUID, api: api)
        responder.refetch = { refetchCount.count += 1 }
        return responder
    }

    @MainActor
    final class RefetchCounter {
        var count = 0
    }

    // MARK: Accept

    @Test("accept sends one POST with an empty object body, then refetches once")
    func acceptSuccess() async throws {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        await responder.accept()

        let posts = Self.acceptPosts()
        #expect(posts.count == 1)
        let body = try #require(posts.first?.jsonBodyForTest())
        #expect(body.isEmpty)
        #expect(counter.count == 1)
        #expect(responder.apiError == nil)
        #expect(responder.isSubmitting == false)
    }

    @Test("a successful accept posts the confirmation toast before the refetch runs")
    func acceptPostsToast() async {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let responder = RescheduleResponder(bookingId: bookingUUID, api: api, toasts: toasts)
        var messageAtRefetch: String?
        responder.refetch = { messageAtRefetch = toasts.current?.message }

        await responder.accept()

        #expect(messageAtRefetch == "Reschedule accepted")
        #expect(toasts.current?.message == "Reschedule accepted")
        toasts.dismiss()
    }

    @Test("PAYMENT_METHOD_REQUIRED retries once with the default saved card")
    func retriesWithDefaultCard() async throws {
        let api = APITestFactory.make { request in
            if Self.isVault(request) {
                return Fixtures.response(for: request, body: Self.vaultBody)
            }
            let hasRetry = Self.acceptPosts().count > 1
            if hasRetry {
                return Fixtures.response(for: request, body: Fixtures.successMessage)
            }
            return Fixtures.response(
                for: request, status: 422, body: Fixtures.errorBody(code: "PAYMENT_METHOD_REQUIRED")
            )
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        await responder.accept()

        let posts = Self.acceptPosts()
        #expect(posts.count == 2)
        let retryBody = try #require(posts.last?.jsonBodyForTest())
        #expect(retryBody["stripe_payment_method_id"] as? String == "pm_default")
        #expect(counter.count == 1)
        #expect(responder.apiError == nil)
    }

    @Test("an empty vault shows the add-a-card copy and sends no second accept")
    func emptyVault() async {
        let api = APITestFactory.make { request in
            if Self.isVault(request) {
                return Fixtures.response(for: request, body: Self.emptyVaultBody)
            }
            return Fixtures.response(
                for: request, status: 422, body: Fixtures.errorBody(code: "PAYMENT_METHOD_REQUIRED")
            )
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        await responder.accept()

        #expect(responder.apiError == "Please add a payment method in Profile > Payment before accepting this reschedule.")
        #expect(Self.acceptPosts().count == 1)
        #expect(counter.count == 0)
    }

    @Test("a failed vault read shows the could-not-check copy")
    func vaultReadFails() async {
        let api = APITestFactory.make { request in
            if Self.isVault(request) {
                return Fixtures.response(for: request, status: 500, body: Fixtures.errorBody(code: "INTERNAL"))
            }
            return Fixtures.response(
                for: request, status: 422, body: Fixtures.errorBody(code: "PAYMENT_METHOD_REQUIRED")
            )
        }
        let responder = makeResponder(api: api, refetchCount: RefetchCounter())

        await responder.accept()

        #expect(responder.apiError == "Couldn't check your saved payment methods. Please try again.")
        #expect(Self.acceptPosts().count == 1)
    }

    @Test("a second PAYMENT_METHOD_REQUIRED shows the unusable-card copy and does not loop")
    func secondPaymentMethodRequiredIsTerminal() async {
        let api = APITestFactory.make { request in
            if Self.isVault(request) {
                return Fixtures.response(for: request, body: Self.vaultBody)
            }
            return Fixtures.response(
                for: request, status: 422, body: Fixtures.errorBody(code: "PAYMENT_METHOD_REQUIRED")
            )
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        await responder.accept()

        #expect(responder.apiError == RescheduleResponder.unusableCardMessage)
        #expect(responder.apiError?.hasPrefix("The card on file can't be used for this reschedule.") == true)
        #expect(Self.acceptPosts().count == 2)
        #expect(counter.count == 0)
    }

    @Test("RESCHEDULE_OUTSIDE_AUTH_WINDOW shows the hold copy")
    func outsideAuthWindow() async {
        let api = APITestFactory.make { request in
            Fixtures.response(
                for: request, status: 422, body: Fixtures.errorBody(code: "RESCHEDULE_OUTSIDE_AUTH_WINDOW")
            )
        }
        let responder = makeResponder(api: api, refetchCount: RefetchCounter())

        await responder.accept()

        #expect(responder.apiError?.hasPrefix("This new time can't be covered by the payment hold on your booking.") == true)
        #expect(responder.apiError?.hasSuffix("so you won't be charged.") == true)
    }

    @Test("RESCHEDULE_OUTSIDE_AUTH_WINDOW on the retry shows the same hold copy")
    func outsideAuthWindowOnRetry() async {
        let api = APITestFactory.make { request in
            if Self.isVault(request) {
                return Fixtures.response(for: request, body: Self.vaultBody)
            }
            let code = Self.acceptPosts().count > 1 ? "RESCHEDULE_OUTSIDE_AUTH_WINDOW" : "PAYMENT_METHOD_REQUIRED"
            return Fixtures.response(for: request, status: 422, body: Fixtures.errorBody(code: code))
        }
        let responder = makeResponder(api: api, refetchCount: RefetchCounter())

        await responder.accept()

        #expect(responder.apiError == RescheduleResponder.outsideAuthWindowMessage)
    }

    @Test("an unmapped code shows the server message")
    func unmappedCodeShowsServerMessage() async {
        let api = APITestFactory.make { request in
            Fixtures.response(
                for: request, status: 409, body: Fixtures.errorBody(code: "SOME_NEW_CODE", message: "Server says no")
            )
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        await responder.accept()

        #expect(responder.apiError == "Server says no")
        #expect(counter.count == 0)
    }

    @Test("two concurrent accept calls record exactly one accept POST")
    func concurrentAcceptSendsOnce() async {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        async let first: Void = responder.accept()
        async let second: Void = responder.accept()
        _ = await (first, second)

        #expect(Self.acceptPosts().count == 1)
        #expect(counter.count == 1)
        #expect(responder.isSubmitting == false)
    }

    // MARK: Decline

    private func declineBody(sending reason: String?) async throws -> [String: Any] {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let responder = makeResponder(api: api, refetchCount: RefetchCounter())
        await responder.decline(reason: reason)
        let post = try #require(Self.declinePosts().first)
        return try #require(post.jsonBodyForTest())
    }

    @Test("a blank reason sends no reason key")
    func blankReasonOmitted() async throws {
        let body = try await declineBody(sending: "   ")
        #expect(body["reason"] == nil)
    }

    @Test("a nil reason sends no reason key")
    func nilReasonOmitted() async throws {
        let body = try await declineBody(sending: nil)
        #expect(body["reason"] == nil)
    }

    @Test("the reason is trimmed")
    func reasonTrimmed() async throws {
        let body = try await declineBody(sending: "  Busy  ")
        #expect(body["reason"] as? String == "Busy")
    }

    @Test("a 600-character reason is sent as 500")
    func longReasonCapped() async throws {
        let body = try await declineBody(sending: String(repeating: "a", count: 600))
        let sent = try #require(body["reason"] as? String)
        #expect(sent.utf16.count == 500)
    }

    @Test("300 family emoji are cut on a character boundary at or under 500 UTF-16 units")
    func emojiReasonCappedWithoutSplitting() async throws {
        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        let reason = String(repeating: family, count: 300)
        let body = try await declineBody(sending: reason)
        let sent = try #require(body["reason"] as? String)
        #expect(sent.utf16.count <= RescheduleResponder.declineReasonLimit)
        #expect(!sent.isEmpty)
        // A whole-character prefix: it is exactly N whole family emoji.
        #expect(sent == String(repeating: family, count: sent.count))
    }

    @Test("a successful decline refetches once")
    func declineRefetches() async {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        await responder.decline(reason: "No")

        #expect(counter.count == 1)
        #expect(responder.apiError == nil)
    }

    @Test("a successful decline posts the declined toast")
    func declinePostsToast() async {
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Fixtures.successMessage)
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let responder = RescheduleResponder(bookingId: bookingUUID, api: api, toasts: toasts)

        await responder.decline(reason: "No")

        #expect(toasts.current?.message == "Reschedule declined")
        toasts.dismiss()
    }

    @Test("a failed accept (409) leaves no toast")
    func failedAcceptShowsNoToast() async {
        let api = APITestFactory.make { request in
            Fixtures.response(
                for: request, status: 409, body: Fixtures.errorBody(code: "SOME_NEW_CODE", message: "Already handled")
            )
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let responder = RescheduleResponder(bookingId: bookingUUID, api: api, toasts: toasts)

        await responder.accept()

        #expect(responder.apiError == "Already handled")
        #expect(toasts.current == nil)
    }

    @Test("a failed decline (409) leaves no toast")
    func failedDeclineShowsNoToast() async {
        let api = APITestFactory.make { request in
            Fixtures.response(
                for: request, status: 409, body: Fixtures.errorBody(code: "SOME_NEW_CODE", message: "Already handled")
            )
        }
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let responder = RescheduleResponder(bookingId: bookingUUID, api: api, toasts: toasts)

        await responder.decline(reason: nil)

        #expect(responder.apiError == "Already handled")
        #expect(toasts.current == nil)
    }

    @Test("a failed decline shows the error and does not refetch")
    func declineFailure() async {
        let api = APITestFactory.make { request in
            Fixtures.response(
                for: request, status: 409, body: Fixtures.errorBody(code: "SOME_NEW_CODE", message: "Already handled")
            )
        }
        let counter = RefetchCounter()
        let responder = makeResponder(api: api, refetchCount: counter)

        await responder.decline(reason: nil)

        #expect(responder.apiError == "Already handled")
        #expect(counter.count == 0)
    }

    // MARK: Accept dialog message

    private func proposal(start: Date, end: Date) -> RescheduleProposal {
        RescheduleProposal(
            proposedStart: start,
            proposedEnd: end,
            proposedTimezone: "UTC",
            initiatedBy: .expert,
            note: nil,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let shortText = "The session will move to the new time the expert proposed."

    @Test("a proposal that ends before the authorization window gets the short text")
    func dialogShortText() {
        let start = now.addingTimeInterval(5 * 86_400)
        let proposal = proposal(start: start, end: start.addingTimeInterval(3600))
        let expiry = start.addingTimeInterval(86_400)

        let text = RescheduleResponder.acceptDialogMessage(
            proposal: proposal, authorizationExpiresAt: expiry, now: now
        )

        #expect(text == shortText)
    }

    @Test("no authorization expiry gets the short text")
    func dialogNoExpiry() {
        let start = now.addingTimeInterval(5 * 86_400)
        let proposal = proposal(start: start, end: start.addingTimeInterval(3600))

        let text = RescheduleResponder.acceptDialogMessage(proposal: proposal, authorizationExpiresAt: nil, now: now)

        #expect(text == shortText)
    }

    @Test("a proposal that ends after the authorization window adds the hold-release disclosure")
    func dialogDisclosure() {
        let start = now.addingTimeInterval(10 * 86_400)
        let proposal = proposal(start: start, end: start.addingTimeInterval(3600))
        let expiry = now.addingTimeInterval(6 * 86_400)

        let text = RescheduleResponder.acceptDialogMessage(
            proposal: proposal, authorizationExpiresAt: expiry, now: now
        )

        #expect(text.hasPrefix(shortText + "\n\nYour card hold will be released."))
        #expect(text.hasSuffix("You won't be charged today."))
        #expect(!text.contains("coming up soon"))
    }

    @Test("a disclosure for a start under 48 hours away adds the near-term caveat")
    func dialogNearTermCaveat() {
        let start = now.addingTimeInterval(30 * 3600)
        let proposal = proposal(start: start, end: start.addingTimeInterval(3600))
        let expiry = now.addingTimeInterval(3600)

        let text = RescheduleResponder.acceptDialogMessage(
            proposal: proposal, authorizationExpiresAt: expiry, now: now
        )

        #expect(text.contains("Your card hold will be released."))
        #expect(text.hasSuffix(
            "\n\nIf your new session is coming up soon, your card may be charged sooner than 24 hours from now."
        ))
    }

    // MARK: UTF16Prefix

    @Test("a string at or under the limit is returned unchanged")
    func prefixUnchangedAtLimit() {
        #expect(UTF16Prefix.prefix("hello", limit: 5) == "hello")
        #expect(UTF16Prefix.prefix("hello", limit: 50) == "hello")
        #expect(UTF16Prefix.prefix("", limit: 0) == "")
    }

    @Test("a surrogate pair is never split")
    func prefixKeepsSurrogatePairsWhole() {
        // U+1F600 is two UTF-16 units. A limit of 3 fits one emoji (2 units), not a second.
        let text = "\u{1F600}\u{1F600}\u{1F600}"
        let cut = UTF16Prefix.prefix(text, limit: 3)
        #expect(cut == "\u{1F600}")
        #expect(cut.utf16.count == 2)
        // An odd limit that would land mid-pair for a unit-based cut.
        #expect(UTF16Prefix.prefix("a\u{1F600}", limit: 2) == "a")
    }

    @Test("a cut ASCII string has exactly the limit's length")
    func prefixAsciiLength() {
        let cut = UTF16Prefix.prefix(String(repeating: "x", count: 10), limit: 4)
        #expect(cut == "xxxx")
    }
}
