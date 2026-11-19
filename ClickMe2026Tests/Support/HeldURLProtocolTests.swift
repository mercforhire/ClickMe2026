//
//  HeldURLProtocolTests.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//
//  WR-15: the test helper itself. A cancelled held request must leave the queue,
//  and `release(where:)` must not hold the lock while it runs the matcher.
//

import Foundation
import Testing
@testable import ClickMe2026

extension HeldResponseTests {

    @Suite("HeldURLProtocol (WR-15)", .serialized)
    @MainActor
    struct HeldURLProtocolTests {

        private static let emptyPage = Data(
            #"{"status":"success","data":{"experts":[],"pagination":{"current_page":1,"total_pages":1,"has_more":false}}}"#.utf8
        )

        @Test("a held request that is cancelled leaves the queue, and release answers the live one")
        func cancelledRequestLeavesQueue() async throws {
            HeldURLProtocol.configure(hold: { _ in true }, otherwise: { _ in (404, Data()) })
            let api = HeldURLProtocol.makeAPI()

            let cancelled = Task { try? await api.getClientFavorites(page: 1, limit: 20) }
            try #require(await waitUntil("the first request to be held") { HeldURLProtocol.heldCount == 1 })
            cancelled.cancel()
            try #require(await waitUntil("the cancelled request to leave the queue") { HeldURLProtocol.heldCount == 0 })
            _ = await cancelled.value

            let live = Task { try await api.getClientFavorites(page: 1, limit: 20) }
            try #require(await waitUntil("the second request to be held") { HeldURLProtocol.heldCount == 1 })

            #expect(HeldURLProtocol.release(where: { _ in true }, body: Self.emptyPage))
            let response = try await live.value

            #expect(response.data.experts.isEmpty)
            #expect(HeldURLProtocol.heldCount == 0)
        }

        @Test("a matcher that reads heldCount does not deadlock release")
        func matcherMayReadHeldCount() async throws {
            HeldURLProtocol.configure(hold: { _ in true }, otherwise: { _ in (404, Data()) })
            let api = HeldURLProtocol.makeAPI()
            let request = Task { try await api.getClientFavorites(page: 1, limit: 20) }
            try #require(await waitUntil("the request to be held") { HeldURLProtocol.heldCount == 1 })

            let released = HeldURLProtocol.release(where: { _ in HeldURLProtocol.heldCount == 1 }, body: Self.emptyPage)
            _ = try await request.value

            #expect(released)
        }
    }
}
