//
//  RequestDecisionAcceptTests.swift
//  ClickMe2026Tests
//
//  EXP-09 (D-11): a 2xx accept replaces Request Decision with Booking Confirmed,
//  and two Confirm taps send one POST. D-12: a 409 ALREADY_PROCESSED pops after
//  the server message, any other error stays. U1: the accept message is capped
//  at 1,000 UTF-16 units with a counter from 800.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Request decision accept", .serialized)
@MainActor
struct RequestDecisionAcceptTests {

    private typealias Fixtures = ClientBookingFixtures

    nonisolated private static let requestId = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
    nonisolated private static let start = Date(timeIntervalSince1970: 4_070_944_800)

    nonisolated private static func isPost(_ request: URLRequest, suffix: String) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix(suffix) == true
    }

    nonisolated private static func posts(suffix: String) -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { isPost($0, suffix: suffix) }
    }

    /// `GET /expert/booking-requests/:id` success envelope: Jane D., Career coaching, 60 minutes, in-app voice.
    nonisolated private static let detailBody = Data(#"""
    {"status":"success","data":{
      "request_id":"44444444-4444-4444-8444-444444444444",
      "client":{"id":"55555555-5555-4555-8555-555555555555","name":"Jane D.","avatar_url":null},
      "session":{
        "start_time":"\#(Fixtures.iso(start))",
        "end_time":"\#(Fixtures.iso(start.addingTimeInterval(3600)))",
        "topic":"Career coaching",
        "meeting_type":"in_app_voice",
        "client_message":"Hi"
      },
      "economics":{"potential_earnings":50,"currency":"USD","earnings_breakdown":null}
    }}
    """#.utf8)

    /// Serves the detail GET plus the given accept and decline answers.
    private func makeAPI(
        acceptStatus: Int = 200,
        acceptBody: Data = Fixtures.successMessage,
        declineStatus: Int = 200,
        declineBody: Data = Fixtures.successMessage
    ) -> ClickMeAPI {
        APITestFactory.make { request in
            if Self.isPost(request, suffix: "/accept") {
                return Fixtures.response(for: request, status: acceptStatus, body: acceptBody)
            }
            if Self.isPost(request, suffix: "/decline") {
                return Fixtures.response(for: request, status: declineStatus, body: declineBody)
            }
            return Fixtures.response(for: request, body: Self.detailBody)
        }
    }

    private func makeLoadedViewModel(
        acceptStatus: Int = 200,
        acceptBody: Data = Fixtures.successMessage,
        declineStatus: Int = 200,
        declineBody: Data = Fixtures.successMessage
    ) async -> RequestDecisionViewModel {
        let viewModel = RequestDecisionViewModel(
            requestId: Self.requestId,
            api: makeAPI(
                acceptStatus: acceptStatus,
                acceptBody: acceptBody,
                declineStatus: declineStatus,
                declineBody: declineBody
            )
        )
        await viewModel.load()
        return viewModel
    }

    // MARK: - Accept success (D-11)

    @Test("before any accept there is no confirmation")
    func startsUnconfirmed() async {
        let viewModel = await makeLoadedViewModel()
        #expect(viewModel.confirmation == nil)
        #expect(viewModel.isAccepted == false)
    }

    @Test("a 2xx accept sets the confirmation, closes the sheet and sends one POST")
    func acceptSuccess() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.openAcceptSheet()
        #expect(viewModel.showAcceptSheet)

        await viewModel.confirmAccept(message: "")

        #expect(viewModel.confirmation?.clientName == "Jane D.")
        #expect(viewModel.confirmation?.topic == "Career coaching")
        #expect(viewModel.showAcceptSheet == false)
        #expect(viewModel.isAccepted)
        #expect(Self.posts(suffix: "/accept").count == 1)
    }

    @Test("two concurrent Confirm taps send exactly one accept")
    func concurrentConfirmSendsOnce() async {
        let viewModel = await makeLoadedViewModel()

        async let first: Void = viewModel.confirmAccept(message: "")
        async let second: Void = viewModel.confirmAccept(message: "")
        _ = await (first, second)

        #expect(Self.posts(suffix: "/accept").count == 1)
        #expect(viewModel.isAccepted)
    }

    @Test("a server error never shows Booking Confirmed")
    func serverErrorLeavesUnconfirmed() async {
        let viewModel = await makeLoadedViewModel(
            acceptStatus: 500,
            acceptBody: Fixtures.errorBody(code: "INTERNAL_ERROR", message: "boom")
        )

        await viewModel.confirmAccept(message: "")

        #expect(viewModel.confirmation == nil)
        #expect(viewModel.isAccepted == false)
    }
}
