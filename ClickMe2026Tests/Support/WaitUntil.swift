//
//  WaitUntil.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Testing

/// Polls `condition` on the main actor until it holds, yielding between checks.
///
/// A timeout records an `Issue` at the call site, so a test that never reached
/// its state fails on that line instead of on whichever assertion follows.
///
/// - Parameters:
///   - description: What the test waits for, shown in the timeout issue.
///   - timeout: The longest wait. A held request is released by the test, not by this.
/// - Returns: Whether the condition held before the timeout.
@MainActor
@discardableResult
func waitUntil(
    _ description: String = "the awaited condition",
    timeout: Duration = .seconds(3),
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: @MainActor () -> Bool
) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else {
            Issue.record("Timed out waiting for \(description).", sourceLocation: sourceLocation)
            return false
        }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return true
}
