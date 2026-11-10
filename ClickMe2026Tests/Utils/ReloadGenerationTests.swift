//
//  ReloadGenerationTests.swift
//  ClickMe2026Tests
//
//  BOOK-18: overlapping refetches (a `booking.update` during a load, a
//  pull-to-refresh during a socket refetch) can land out of order. Only the
//  most recently started fetch may write the screen.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("ReloadGeneration")
struct ReloadGenerationTests {

    /// Stand-in for a screen that refetches: every load takes a token before
    /// its first await and writes `shown` only while that token is current.
    @MainActor
    private final class FakeScreen {
        var gate = ReloadGeneration()
        var shown: String?
        /// Continuations of fetches that are waiting for the test to resume them.
        var waiting: [CheckedContinuation<String, Never>] = []

        func load() async {
            let token = gate.begin()
            let result = await withCheckedContinuation { continuation in
                waiting.append(continuation)
            }
            guard gate.isCurrent(token) else { return }
            shown = result
        }
    }

    /// Yields until `count` fetches are suspended on their continuation.
    private static func waitUntil(_ screen: FakeScreen, hasWaiting count: Int) async {
        while screen.waiting.count < count {
            await Task.yield()
        }
    }

    @Test("a token from begin() is current")
    func freshTokenIsCurrent() {
        var gate = ReloadGeneration()
        let token = gate.begin()
        #expect(gate.isCurrent(token))
    }

    @Test("after a second begin() only the second token is current")
    func secondBeginSupersedesFirst() {
        var gate = ReloadGeneration()
        let first = gate.begin()
        let second = gate.begin()
        #expect(!gate.isCurrent(first))
        #expect(gate.isCurrent(second))
    }

    @Test("checking order does not change the answer")
    func checkOrderDoesNotMatter() {
        var gate = ReloadGeneration()
        let first = gate.begin()
        let second = gate.begin()
        #expect(gate.isCurrent(second))
        #expect(!gate.isCurrent(first))
    }

    @Test("out-of-order completion leaves the newer value on screen")
    func newerFetchResumedFirst() async {
        let screen = FakeScreen()
        async let older: Void = screen.load()
        await Self.waitUntil(screen, hasWaiting: 1)
        async let newer: Void = screen.load()
        await Self.waitUntil(screen, hasWaiting: 2)

        // The newer fetch's response lands first, the older one last.
        screen.waiting[1].resume(returning: "newer")
        screen.waiting[0].resume(returning: "older")
        await older
        await newer

        #expect(screen.shown == "newer")
    }

    @Test("in-order completion also leaves the newer value on screen")
    func olderFetchResumedFirst() async {
        let screen = FakeScreen()
        async let older: Void = screen.load()
        await Self.waitUntil(screen, hasWaiting: 1)
        async let newer: Void = screen.load()
        await Self.waitUntil(screen, hasWaiting: 2)

        screen.waiting[0].resume(returning: "older")
        screen.waiting[1].resume(returning: "newer")
        await older
        await newer

        #expect(screen.shown == "newer")
    }
}
