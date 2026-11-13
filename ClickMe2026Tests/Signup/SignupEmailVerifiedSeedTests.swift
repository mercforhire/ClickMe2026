//
//  SignupEmailVerifiedSeedTests.swift
//  ClickMe2026Tests
//
//  SIGN-02: the setup hub seeds `emailVerified` from `GET /auth/email/status`.
//  A true answer ticks the row, a false answer or a failed call leaves it
//  alone, and a local true is never downgraded and costs no request.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Signup email verified seed", .serialized)
struct SignupEmailVerifiedSeedTests {

    // MARK: - Fixtures

    /// A client whose every request answers with `status` and `body`.
    private static func makeAPI(status: Int, body: String) -> ClickMeAPI {
        APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(body.utf8))
        }
    }

    private static func verifiedBody(_ verified: Bool) -> String {
        "{\"status\":\"success\",\"data\":{\"verified\":\(verified)}}"
    }

    private static func statusRequestCount() -> Int {
        MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/auth/email/status") == true }.count
    }

    // MARK: - Tests

    @Test("A verified answer from the server ticks the Verify email row")
    func verifiedAnswerSeedsFlag() async {
        let api = Self.makeAPI(status: 200, body: Self.verifiedBody(true))
        let accumulator = SignupAccumulator()
        #expect(!accumulator.emailVerified)

        await accumulator.refreshEmailVerified(using: api)

        #expect(accumulator.emailVerified)
        #expect(accumulator.checklist.emailVerified)
        #expect(Self.statusRequestCount() == 1)
    }

    @Test("An unverified answer leaves the flag false")
    func unverifiedAnswerKeepsFlag() async {
        let api = Self.makeAPI(status: 200, body: Self.verifiedBody(false))
        let accumulator = SignupAccumulator()

        await accumulator.refreshEmailVerified(using: api)

        #expect(!accumulator.emailVerified)
        #expect(!accumulator.checklist.emailVerified)
        #expect(Self.statusRequestCount() == 1)
    }

    @Test("A failed status call leaves the flag false")
    func failedCallKeepsFlag() async {
        let api = Self.makeAPI(status: 500, body: "{\"status\":\"error\",\"message\":\"boom\"}")
        let accumulator = SignupAccumulator()

        await accumulator.refreshEmailVerified(using: api)

        #expect(!accumulator.emailVerified)
        #expect(Self.statusRequestCount() == 1)
    }

    @Test("A local true is never downgraded and makes no request")
    func localTrueIsKept() async {
        let api = Self.makeAPI(status: 200, body: Self.verifiedBody(false))
        let accumulator = SignupAccumulator()
        accumulator.emailVerified = true

        await accumulator.refreshEmailVerified(using: api)

        #expect(accumulator.emailVerified)
        #expect(Self.statusRequestCount() == 0)
    }
}
