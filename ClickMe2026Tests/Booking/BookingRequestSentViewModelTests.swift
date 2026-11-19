//
//  BookingRequestSentViewModelTests.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//
//  The load failure text on the Request Sent screen (IN-12) and how a cancelled
//  load is treated (IN-15).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Request Sent view model", .serialized)
@MainActor
struct BookingRequestSentViewModelTests {

    private static let genericError = "Something went wrong. Please try again."

    nonisolated private static func reply(
        _ request: URLRequest,
        status: Int,
        body: String
    ) -> (HTTPURLResponse, Data) {
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (http, Data(body.utf8))
    }

    @Test("a failed load shows the server's message")
    func failedLoadShowsServerMessage() async {
        let api = APITestFactory.make { request in
            Self.reply(request, status: 404, body: #"{"status":"error","code":"NOT_FOUND","message":"No such booking"}"#)
        }
        let viewModel = BookingRequestSentViewModel(bookingId: UUID(), api: api)

        await viewModel.load()

        #expect(viewModel.state == .failed("No such booking"))
    }

    @Test("a failed load with a body that is not an error envelope shows the generic text")
    func failedLoadWithUnreadableBodyShowsGenericText() async {
        let api = APITestFactory.make { request in
            Self.reply(request, status: 502, body: "<html>bad gateway</html>")
        }
        let viewModel = BookingRequestSentViewModel(bookingId: UUID(), api: api)

        await viewModel.load()

        #expect(viewModel.state == .failed(Self.genericError))
    }
}
