//
//  ConfirmOutcomeTests.swift
//  ClickMe2026Tests
//
//  PAY-02 (D-03): which confirm failures leave the booking outcome unknown, and
//  how the bounded retry behaves. Pure logic, no URLSession.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Confirm outcome")
struct ConfirmOutcomeTests {

    // MARK: Fixtures

    private func httpError(_ status: Int, code: String? = nil) -> NetworkError {
        let body: String
        if let code {
            body = #"{"status":"error","code":"\#(code)","message":"server text"}"#
        } else {
            body = "<html><body>Bad Gateway</body></html>"
        }
        return .httpError(statusCode: status, data: Data(body.utf8))
    }

    private struct Boom: Error {}

    // MARK: Classifier

    @Test("Transport failures are an unknown outcome", arguments: [
        URLError(.timedOut),
        URLError(.networkConnectionLost),
        URLError(.notConnectedToInternet),
    ])
    func urlErrorsAreUnknown(_ error: URLError) {
        #expect(ConfirmOutcome.classify(error) == .outcomeUnknown)
    }

    @Test("A cancelled task is an unknown outcome")
    func cancellationIsUnknown() {
        #expect(ConfirmOutcome.classify(CancellationError()) == .outcomeUnknown)
    }

    @Test("An unreadable response is an unknown outcome")
    func invalidResponseAndDecodingAreUnknown() {
        #expect(ConfirmOutcome.classify(NetworkError.invalidResponse) == .outcomeUnknown)
        #expect(ConfirmOutcome.classify(NetworkError.decodingFailed(Boom())) == .outcomeUnknown)
    }

    @Test("A 5xx the flow does not map is an unknown outcome")
    func unmapped5xxIsUnknown() {
        #expect(ConfirmOutcome.classify(httpError(502)) == .outcomeUnknown)
        #expect(ConfirmOutcome.classify(httpError(500, code: "INTERNAL_ERROR")) == .outcomeUnknown)
        #expect(ConfirmOutcome.classify(httpError(504, code: "SOME_NEW_CODE")) == .outcomeUnknown)
    }

    @Test("A coded answer is server-coded, even from a 5xx")
    func codedAnswersAreServerCoded() {
        #expect(ConfirmOutcome.classify(httpError(503, code: "DIRECT_CHARGE_DISABLED")) == .serverCoded)
        #expect(ConfirmOutcome.classify(httpError(402, code: "PAYMENT_REQUIRES_ACTION")) == .serverCoded)
        #expect(ConfirmOutcome.classify(httpError(409, code: "SLOT_UNAVAILABLE")) == .serverCoded)
        #expect(ConfirmOutcome.classify(httpError(422, code: "INTENT_EXPIRED")) == .serverCoded)
    }

    @Test("PI_CURRENCY_MISMATCH is one of the mapped codes, so a 5xx carrying it is server-coded")
    func currencyMismatchIsMapped() {
        #expect(ConfirmOutcome.explicitlyMappedCodes.contains(.piCurrencyMismatch))
        #expect(ConfirmOutcome.classify(httpError(503, code: "PI_CURRENCY_MISMATCH")) == .serverCoded)
    }

    @Test("Every explicitly mapped code stays server-coded on a 500")
    func mappedCodesStayCodedOn500() {
        for code in ConfirmOutcome.explicitlyMappedCodes {
            #expect(ConfirmOutcome.classify(httpError(500, code: code.rawValue)) == .serverCoded)
        }
    }

    // MARK: PAYMENT_IN_PROGRESS (D-17)

    @Test("409 PAYMENT_IN_PROGRESS is an unknown outcome")
    func paymentInProgressIsUnknown() {
        #expect(ConfirmOutcome.classify(httpError(409, code: "PAYMENT_IN_PROGRESS")) == .outcomeUnknown)
    }

    @Test("Other 4xx answers stay server-coded, known or not")
    func other4xxStayServerCoded() {
        #expect(ConfirmOutcome.classify(httpError(409, code: "SLOT_UNAVAILABLE")) == .serverCoded)
        #expect(ConfirmOutcome.classify(httpError(409, code: "A_CODE_THE_APP_DOES_NOT_KNOW")) == .serverCoded)
        #expect(ConfirmOutcome.classify(httpError(409, code: "DUPLICATE_BOOKING")) == .serverCoded)
    }

    @Test("PAYMENT_IN_PROGRESS is the only code in the unknown set")
    func onlyPaymentInProgress() {
        #expect(ConfirmOutcome.outcomeUnknownCodes == [.paymentInProgress])
        #expect(ErrorCode(rawValue: "PAYMENT_IN_PROGRESS") == .paymentInProgress)
    }

    @Test("PAYMENT_IN_PROGRESS then success makes two calls and succeeds")
    func paymentInProgressThenSuccess() async {
        var calls = 0
        let result = await noWait.run { () async throws -> Int in
            calls += 1
            if calls == 1 { throw httpError(409, code: "PAYMENT_IN_PROGRESS") }
            return 3
        }
        #expect(calls == 2)
        guard case let .succeeded(value) = result else {
            Issue.record("expected success")
            return
        }
        #expect(value == 3)
    }

    @Test("Three PAYMENT_IN_PROGRESS answers make three calls and end unknown")
    func paymentInProgressThreeTimes() async {
        var calls = 0
        let result = await noWait.run { () async throws -> Int in
            calls += 1
            throw httpError(409, code: "PAYMENT_IN_PROGRESS")
        }
        #expect(calls == 3)
        guard case .outcomeUnknown = result else {
            Issue.record("expected outcomeUnknown")
            return
        }
    }

    @Test("PAYMENT_IN_PROGRESS has no copy of its own: the server text is the fallback")
    func paymentInProgressHasNoMappedCopy() {
        #expect(BookingErrorMapper.message(for: .paymentInProgress, fallback: "server text") == "server text")
    }

    // MARK: Retry policy

    private let noWait = ConfirmRetryPolicy(delays: [.zero, .zero])

    @Test("Success on the first try makes one call")
    func successFirstTry() async {
        var calls = 0
        let result = await noWait.run { () async throws -> Int in
            calls += 1
            return 7
        }
        #expect(calls == 1)
        guard case let .succeeded(value) = result else {
            Issue.record("expected success")
            return
        }
        #expect(value == 7)
    }

    @Test("Two unknown failures then success makes three calls and succeeds")
    func unknownThenSuccess() async {
        var calls = 0
        let result = await noWait.run { () async throws -> Int in
            calls += 1
            if calls < 3 { throw URLError(.timedOut) }
            return 9
        }
        #expect(calls == 3)
        guard case let .succeeded(value) = result else {
            Issue.record("expected success")
            return
        }
        #expect(value == 9)
    }

    @Test("Three unknown failures make three calls and end unknown")
    func threeUnknowns() async {
        var calls = 0
        let result = await noWait.run { () async throws -> Int in
            calls += 1
            throw URLError(.networkConnectionLost)
        }
        #expect(calls == 3)
        guard case .outcomeUnknown = result else {
            Issue.record("expected outcomeUnknown")
            return
        }
    }

    @Test("An unknown failure then a coded error makes two calls and ends server-coded")
    func unknownThenCoded() async {
        var calls = 0
        let result = await noWait.run { () async throws -> Int in
            calls += 1
            if calls == 1 { throw URLError(.timedOut) }
            throw httpError(409, code: "SLOT_UNAVAILABLE")
        }
        #expect(calls == 2)
        guard case .serverCoded = result else {
            Issue.record("expected serverCoded")
            return
        }
    }

    @Test("A coded error on the first try is not retried")
    func codedIsNotRetried() async {
        var calls = 0
        let result = await noWait.run { () async throws -> Int in
            calls += 1
            throw httpError(422, code: "INTENT_EXPIRED")
        }
        #expect(calls == 1)
        guard case .serverCoded = result else {
            Issue.record("expected serverCoded")
            return
        }
    }

    @Test("The standard policy waits 2 s and then 4 s")
    func standardDelays() {
        #expect(ConfirmRetryPolicy.standard.delays == [.seconds(2), .seconds(4)])
    }
}
