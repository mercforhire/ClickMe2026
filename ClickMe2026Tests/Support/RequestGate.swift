//
//  RequestGate.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Holds a stubbed response until `open()` is called, so a test can change state
/// while a request is in flight.
///
/// Call `waitIfArmed()` at the top of a `MockURLProtocol` handler. It blocks only
/// while the gate is armed, and for at most five seconds so a broken test cannot
/// hang. `open()` releases the waiting request and disarms the gate, so requests
/// that come later go straight through.
final class RequestGate: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var armed = false

    func arm() {
        lock.withLock { armed = true }
    }

    func waitIfArmed() {
        guard lock.withLock({ armed }) else { return }
        _ = semaphore.wait(timeout: .now() + 5)
    }

    func open() {
        lock.withLock { armed = false }
        semaphore.signal()
    }
}
