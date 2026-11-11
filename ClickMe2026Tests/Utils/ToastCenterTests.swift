//
//  ToastCenterTests.swift
//  ClickMe2026Tests
//
//  BOOK-06 / UI-SPEC section 10: one toast at a time, a replacing message
//  restarts the timer, a tap dismisses early.
//
//  The dismiss timer runs on a `ManualSleeper`, so no assertion depends on
//  wall-clock timing.
//

import Foundation
import Testing
@testable import ClickMe2026

/// A stand-in for `Task.sleep` that a test releases by hand. Each call
/// suspends until `release(_:)` or until its task is cancelled, so a replaced
/// or dismissed toast's timer ends exactly as it does in production.
private actor ManualSleeper {
    private var waiters: [Int: CheckedContinuation<Void, Error>] = [:]
    private(set) var callCount = 0

    func sleep() async throws {
        let index = callCount
        callCount += 1
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else {
                    waiters[index] = continuation
                }
            }
        } onCancel: {
            Task { await self.cancel(index) }
        }
    }

    /// Lets the `index`-th sleep (in call order) finish normally. A sleep that
    /// was already cancelled is gone, so releasing it does nothing.
    func release(_ index: Int) {
        waiters.removeValue(forKey: index)?.resume()
    }

    private func cancel(_ index: Int) {
        waiters.removeValue(forKey: index)?.resume(throwing: CancellationError())
    }
}

@MainActor
@Suite("Toast center")
struct ToastCenterTests {

    private func makeCenter() -> (ToastCenter, ManualSleeper) {
        let sleeper = ManualSleeper()
        let center = ToastCenter(displayDuration: .seconds(4), sleep: { _ in try await sleeper.sleep() })
        return (center, sleeper)
    }

    /// Yields until `condition` holds, failing after a generous bound.
    private func wait(
        for condition: @MainActor () async -> Bool,
        _ message: Comment,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        for _ in 0..<10_000 {
            if await condition() { return }
            await Task.yield()
        }
        Issue.record(message, sourceLocation: sourceLocation)
    }

    /// Lets already-runnable tasks (a cancelled timer waking up) run.
    private func settle() async {
        for _ in 0..<100 { await Task.yield() }
    }

    @Test("show sets the message and a second show replaces it")
    func showReplaces() {
        let (center, _) = makeCenter()

        center.show("A")
        #expect(center.current?.message == "A")

        center.show("B")
        #expect(center.current?.message == "B")
        center.dismiss()
    }

    @Test("a replacing show restarts the timer, and the toast then clears")
    func replacementRestartsTimer() async {
        let (center, sleeper) = makeCenter()

        center.show("A")
        await wait(for: { await sleeper.callCount == 1 }, "A's timer never started")
        center.show("B")
        await wait(for: { await sleeper.callCount == 2 }, "B's timer never started")

        // A's timer was cancelled by the replacement. Letting it run out must not cut B short.
        await sleeper.release(0)
        await settle()
        #expect(center.current?.message == "B")

        await sleeper.release(1)
        await wait(for: { center.current == nil }, "B never cleared after its own timer ended")
    }

    @Test("dismiss clears the toast immediately")
    func dismissClears() {
        let (center, _) = makeCenter()

        center.show("A", systemImage: "checkmark.circle.fill")
        #expect(center.current?.systemImage == "checkmark.circle.fill")

        center.dismiss()
        #expect(center.current == nil)
    }

    @Test("a toast shown after a dismiss still gets its full duration")
    func showAfterDismiss() async {
        let (center, sleeper) = makeCenter()

        center.show("A")
        await wait(for: { await sleeper.callCount == 1 }, "A's timer never started")
        center.dismiss()
        center.show("B")
        await wait(for: { await sleeper.callCount == 2 }, "B's timer never started")

        // The dismissed toast's timer ending must not clear B.
        await sleeper.release(0)
        await settle()
        #expect(center.current?.message == "B")

        await sleeper.release(1)
        await wait(for: { center.current == nil }, "B never cleared after its own timer ended")
    }
}
