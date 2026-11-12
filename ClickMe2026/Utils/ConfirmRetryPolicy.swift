//
//  ConfirmRetryPolicy.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Bounded retry of one idempotent request whose outcome can be unknown.
///
/// The same request is sent again only while `ConfirmOutcome.classify` says the
/// outcome is unknown, once after each delay. The first success or the first
/// server-coded error ends the run. The standard policy makes up to three
/// attempts, 2 s and then 4 s apart (PAY-02, D-03).
struct ConfirmRetryPolicy {

    /// How a run ended.
    ///
    /// Named `RunResult` so it does not shadow the standard library's result type.
    enum RunResult<Value> {
        case succeeded(Value)
        case serverCoded(Error)
        case outcomeUnknown(Error)
    }

    /// The wait before each retry. `delays.count` is the number of retries.
    let delays: [Duration]

    /// One attempt plus two automatic retries, 2 s then 4 s apart.
    static let standard = ConfirmRetryPolicy(delays: [.seconds(2), .seconds(4)])

    /// Runs `attempt`, then runs it again after each delay while the failure is
    /// an unknown outcome.
    ///
    /// - Parameter attempt: The request. Every call must send the same request
    ///   (same PaymentIntent, card and attempt id), so a retry can only replay.
    /// - Returns: The first success, the first server-coded error, or the last
    ///   unknown-outcome error once the delays run out.
    func run<Value>(_ attempt: () async throws -> Value) async -> RunResult<Value> {
        var remainingDelays = delays[...]
        while true {
            do {
                return .succeeded(try await attempt())
            } catch {
                switch ConfirmOutcome.classify(error) {
                case .serverCoded:
                    return .serverCoded(error)
                case .outcomeUnknown:
                    guard let delay = remainingDelays.popFirst() else {
                        return .outcomeUnknown(error)
                    }
                    try? await Task.sleep(for: delay)
                }
            }
        }
    }
}
