//
//  BookingErrorCopyParityTests.swift
//  ClickMe2026Tests
//
//  PAY-05: the free and the paid Make a Booking paths show the same text for
//  the same ErrorCode. Runs through the real view model with the API answering
//  every request from a mocked URLSession, so no real hold is ever placed.
//

import Foundation
import Testing
@testable import ClickMe2026

/// Records the request paths a mocked handler saw. The handler runs on a URL
/// loading thread, so access goes through a lock.
private final class PathLog: @unchecked Sendable {
    private let lock = NSLock()
    private var paths: [String] = []

    func record(_ path: String) {
        lock.lock(); defer { lock.unlock() }
        paths.append(path)
    }

    var all: [String] {
        lock.lock(); defer { lock.unlock() }
        return paths
    }
}

private enum ParityFixture {
    static let serverText = "raw server text"

    static let freeTopic = BookingTopic(
        id: UUID(), title: "Free chat", durationMinutes: 30, description: nil,
        priceAmount: nil, currency: nil, isFree: true
    )
    static let paidTopic = BookingTopic(
        id: UUID(), title: "Paid session", durationMinutes: 30, description: nil,
        priceAmount: 5000, currency: "USD", isFree: false
    )

    nonisolated static func errorBody(code: String, message: String = serverText) -> Data {
        Data(#"{"status":"error","code":"\#(code)","message":"\#(message)"}"#.utf8)
    }

    nonisolated static func response(for request: URLRequest, status: Int, body: Data) -> (HTTPURLResponse, Data) {
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (http, body)
    }
}

@Suite("Booking error copy parity", .serialized)
@MainActor
struct BookingErrorCopyParityTests {

    /// A view model on `topic` with a slot 2 days ahead picked, and an API
    /// that answers every request with `status` and `body`.
    private func makeViewModel(
        topic: BookingTopic,
        status: Int,
        body: Data,
        log: PathLog
    ) -> MakeABookingViewModel {
        let api = APITestFactory.make { request in
            log.record(request.url?.path ?? "")
            return ParityFixture.response(for: request, status: status, body: body)
        }
        let viewModel = MakeABookingViewModel(
            expertName: "Ada Lovelace",
            expertTitle: "Engineer",
            expertImageURL: "",
            topics: [topic],
            api: api
        )
        viewModel.selectedTopic = topic
        viewModel.selectedTimeSlot = BookingTimeSlot(
            startTime: Date().addingTimeInterval(2 * 24 * 3600),
            endTime: nil,
            isAvailable: true
        )
        return viewModel
    }

    /// Calls `book()` and waits (20 ms steps, up to 3 s) for the error text.
    private func bookAndWait(_ viewModel: MakeABookingViewModel) async -> String? {
        viewModel.book()
        for _ in 0 ..< 150 {
            if viewModel.bookingError != nil { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return viewModel.bookingError
    }

    @Test("409 SLOT_UNAVAILABLE: free and paid show the same text and clear the slot")
    func slotUnavailable() async {
        MockURLProtocol.reset()
        let expected = "That time slot was just taken. Please pick another."
        let body = ParityFixture.errorBody(code: "SLOT_UNAVAILABLE")

        let free = makeViewModel(topic: ParityFixture.freeTopic, status: 409, body: body, log: PathLog())
        #expect(await bookAndWait(free) == expected)
        #expect(free.selectedTimeSlot == nil)

        let paid = makeViewModel(topic: ParityFixture.paidTopic, status: 409, body: body, log: PathLog())
        #expect(await bookAndWait(paid) == expected)
        #expect(paid.selectedTimeSlot == nil)
    }

    @Test("422 MEETING_LINK_UNAVAILABLE: free and paid show the same text")
    func meetingLinkUnavailable() async {
        MockURLProtocol.reset()
        let expected = "The expert hasn't set up their Skype/Zoom link yet. Please choose in-app voice instead."
        let body = ParityFixture.errorBody(code: "MEETING_LINK_UNAVAILABLE")

        let free = makeViewModel(topic: ParityFixture.freeTopic, status: 422, body: body, log: PathLog())
        #expect(await bookAndWait(free) == expected)

        let paid = makeViewModel(topic: ParityFixture.paidTopic, status: 422, body: body, log: PathLog())
        #expect(await bookAndWait(paid) == expected)
    }

    @Test("422 LONG_LEAD_REQUIRES_SAVED_CARD on the paid path: clear error, no confirm call")
    func longLeadNeverConfirms() async {
        MockURLProtocol.reset()
        let log = PathLog()
        let body = ParityFixture.errorBody(code: "LONG_LEAD_REQUIRES_SAVED_CARD")

        let paid = makeViewModel(topic: ParityFixture.paidTopic, status: 422, body: body, log: log)
        #expect(await bookAndWait(paid) == BookingErrorMapper.longLeadMessage)
        #expect(paid.selectedTimeSlot == nil)
        #expect(paid.paidStep == .idle)
        #expect(!log.all.contains { $0.hasSuffix("/bookings/confirm") })
        #expect(log.all.contains { $0.hasSuffix("/bookings/payment-intent") })
    }

    @Test("422 LONG_LEAD_NOT_AVAILABLE on the paid path: clear error, no confirm call")
    func longLeadNotAvailableNeverConfirms() async {
        MockURLProtocol.reset()
        let log = PathLog()
        let body = ParityFixture.errorBody(code: "LONG_LEAD_NOT_AVAILABLE")

        let paid = makeViewModel(topic: ParityFixture.paidTopic, status: 422, body: body, log: log)
        #expect(await bookAndWait(paid) == BookingErrorMapper.longLeadMessage)
        #expect(!log.all.contains { $0.hasSuffix("/bookings/confirm") })
    }

    @Test("400 with an unmapped code: free and paid both show the server message")
    func unmappedCodeShowsServerMessage() async {
        MockURLProtocol.reset()
        let body = ParityFixture.errorBody(code: "INTERNAL_ERROR")

        let free = makeViewModel(topic: ParityFixture.freeTopic, status: 400, body: body, log: PathLog())
        #expect(await bookAndWait(free) == ParityFixture.serverText)

        let paid = makeViewModel(topic: ParityFixture.paidTopic, status: 400, body: body, log: PathLog())
        #expect(await bookAndWait(paid) == ParityFixture.serverText)
    }
}
