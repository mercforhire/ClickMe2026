//
//  ClientCancellationViewModelTests.swift
//  ClickMe2026Tests
//
//  BOOK-08 (D-06): the refund preview is re-checked at the moment of confirm.
//  A case that changed since it was shown blocks the submit once, the next tap
//  sends the cancel, and a server error leaves the client on the confirm step.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Client cancellation view model", .serialized)
@MainActor
struct ClientCancellationViewModelTests {

    private typealias Fixtures = ClientBookingFixtures

    /// The clock the view model reads. Tests move `now` between taps.
    @MainActor
    final class TestClock {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    private static let base = Date(timeIntervalSince1970: 1_800_000_000)

    private static let cancelSuccess = Data(#"""
    {"status":"success","message":"Booking cancelled successfully. Refund processed if applicable.","data":{"refund_amount":0,"currency":"CAD"}}
    """#.utf8)

    nonisolated private static func isCancel(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/cancel") == true
    }

    nonisolated private static func cancelPosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isCancel)
    }

    /// Serves one detail payload and the given cancel response.
    private func makeAPI(
        detail: Data,
        cancelStatus: Int = 200,
        cancelBody: Data = ClientCancellationViewModelTests.cancelSuccess
    ) -> ClickMeAPI {
        APITestFactory.make { request in
            if Self.isCancel(request) {
                return Fixtures.response(for: request, status: cancelStatus, body: cancelBody)
            }
            return Fixtures.response(for: request, body: detail)
        }
    }

    /// A paid CAD 4500 booking charged (captured) and starting `secondsAhead` after `base`.
    private func capturedDetail(secondsAhead: TimeInterval) -> Data {
        Fixtures.detailJSON(
            start: Self.base.addingTimeInterval(secondsAhead),
            end: Self.base.addingTimeInterval(secondsAhead + 3600),
            paymentStatus: "captured",
            isFree: false,
            priceAmount: 4500,
            currency: "CAD"
        )
    }

    private func makeLoadedViewModel(
        detail: Data,
        clock: TestClock,
        cancelStatus: Int = 200,
        cancelBody: Data = ClientCancellationViewModelTests.cancelSuccess,
        toasts: ToastCenter = ToastCenter(displayDuration: .seconds(60))
    ) async -> ClientCancellationViewModel {
        let viewModel = ClientCancellationViewModel(
            bookingId: UUID(uuidString: Fixtures.bookingId)!,
            api: makeAPI(detail: detail, cancelStatus: cancelStatus, cancelBody: cancelBody),
            now: { clock.now },
            toasts: toasts
        )
        await viewModel.load()
        return viewModel
    }

    /// Counts `onConfirm` calls from a `@Sendable`-free closure.
    @MainActor
    final class ConfirmCounter {
        var count = 0
    }

    // MARK: - Tests

    @Test("a case that changed since it was shown blocks the first tap, the second tap submits")
    func changedCaseBlocksOnce() async {
        let clock = TestClock(Self.base)
        let viewModel = await makeLoadedViewModel(
            detail: capturedDetail(secondsAhead: CancelRefundPreview.refundWindow + 30),
            clock: clock
        )
        guard case .chargedRefundable = viewModel.booking.refundCase else {
            Issue.record("expected .chargedRefundable at load, got \(String(describing: viewModel.booking.refundCase))")
            return
        }
        let confirmed = ConfirmCounter()

        // The session crosses the 24-hour line while the step is open.
        clock.now = Self.base.addingTimeInterval(60)
        await viewModel.confirmCancellation { _, _ in confirmed.count += 1 }

        #expect(Self.cancelPosts().isEmpty)
        #expect(confirmed.count == 0)
        #expect(viewModel.previewChangedNotice)
        guard case .chargedNotRefundable = viewModel.booking.refundCase else {
            Issue.record("expected .chargedNotRefundable after the tap, got \(String(describing: viewModel.booking.refundCase))")
            return
        }

        await viewModel.confirmCancellation { _, _ in confirmed.count += 1 }

        #expect(Self.cancelPosts().count == 1)
        #expect(confirmed.count == 1)
        #expect(viewModel.previewChangedNotice == false)
    }

    @Test("an unchanged case submits on the first tap")
    func unchangedCaseSubmitsImmediately() async {
        let clock = TestClock(Self.base)
        let viewModel = await makeLoadedViewModel(
            detail: capturedDetail(secondsAhead: 3 * 24 * 3600),
            clock: clock
        )
        let confirmed = ConfirmCounter()

        await viewModel.confirmCancellation { _, _ in confirmed.count += 1 }

        #expect(Self.cancelPosts().count == 1)
        #expect(Self.cancelPosts().first?.url?.path.hasSuffix("/client/bookings/\(Fixtures.bookingId)/cancel") == true)
        #expect(confirmed.count == 1)
        #expect(viewModel.previewChangedNotice == false)
        #expect(viewModel.cancelError == nil)
    }

    @Test("a free booking loads as .free and submits with no notice")
    func freeBookingSubmits() async {
        let clock = TestClock(Self.base)
        let viewModel = await makeLoadedViewModel(
            detail: Fixtures.detailJSON(
                start: Self.base.addingTimeInterval(2 * 3600),
                end: Self.base.addingTimeInterval(3 * 3600)
            ),
            clock: clock
        )
        #expect(viewModel.booking.refundCase == .free)
        let confirmed = ConfirmCounter()

        await viewModel.confirmCancellation { _, _ in confirmed.count += 1 }

        #expect(Self.cancelPosts().count == 1)
        #expect(confirmed.count == 1)
        #expect(viewModel.previewChangedNotice == false)
    }

    @Test("SESSION_ALREADY_ENDED shows the server message and does not confirm")
    func sessionAlreadyEnded() async {
        let clock = TestClock(Self.base)
        let message = "This session has already ended."
        let viewModel = await makeLoadedViewModel(
            detail: capturedDetail(secondsAhead: 3 * 24 * 3600),
            clock: clock,
            cancelStatus: 409,
            cancelBody: Fixtures.errorBody(code: "SESSION_ALREADY_ENDED", message: message)
        )
        let confirmed = ConfirmCounter()

        await viewModel.confirmCancellation { _, _ in confirmed.count += 1 }

        #expect(viewModel.cancelError == message)
        #expect(confirmed.count == 0)
        #expect(viewModel.isConfirming == false)
    }

    // MARK: - Post-cancel toast (D-06)

    @Test("a 200 with refund_amount 45 posts the refund toast and confirms once")
    func successPostsRefundToast() async {
        let clock = TestClock(Self.base)
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let viewModel = await makeLoadedViewModel(
            detail: capturedDetail(secondsAhead: 3 * 24 * 3600),
            clock: clock,
            cancelBody: Data(#"{"status":"success","message":"ok","data":{"refund_amount":45,"currency":"CAD"}}"#.utf8),
            toasts: toasts
        )
        let confirmed = ConfirmCounter()

        await viewModel.confirmCancellation { _, _ in confirmed.count += 1 }

        #expect(toasts.current?.message == "Booking cancelled. CA$45.00 will be refunded to your card.")
        #expect(confirmed.count == 1)
    }

    @Test("a zero refund after confirming under a refundable charge says the refund is being processed")
    func zeroRefundUsesConfirmedCase() async {
        let clock = TestClock(Self.base)
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let viewModel = await makeLoadedViewModel(
            detail: capturedDetail(secondsAhead: 3 * 24 * 3600),
            clock: clock,
            toasts: toasts
        )

        await viewModel.confirmCancellation { _, _ in }

        #expect(toasts.current?.message == "Booking cancelled. Your CA$45.00 refund is being processed.")
    }

    @Test("a 409 shows the error, posts no toast and does not confirm")
    func failurePostsNoToast() async {
        let clock = TestClock(Self.base)
        let toasts = ToastCenter(displayDuration: .seconds(60))
        let viewModel = await makeLoadedViewModel(
            detail: capturedDetail(secondsAhead: 3 * 24 * 3600),
            clock: clock,
            cancelStatus: 409,
            cancelBody: Fixtures.errorBody(code: "SESSION_ALREADY_ENDED", message: "This session has already ended."),
            toasts: toasts
        )
        let confirmed = ConfirmCounter()

        await viewModel.confirmCancellation { _, _ in confirmed.count += 1 }

        #expect(viewModel.cancelError != nil)
        #expect(toasts.current == nil)
        #expect(confirmed.count == 0)
    }
}
