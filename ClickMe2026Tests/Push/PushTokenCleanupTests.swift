//
//  PushTokenCleanupTests.swift
//  ClickMe2026Tests
//
//  PUSH-04: a user logout sends the server DELETE while the session is
//  still signed in, then clears the session, then deletes the FCM token.
//  Each network step is cut off at the timeout and a failed or timed-out
//  step never stops logout; it leaves the deleteToken-only retry marker
//  (D-17, D-18).
//
//  Every row drives `PushTokenCleanup` through fakes that append to an
//  events array, against a throwaway `UserDefaults` suite that the row
//  removes afterwards.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Push token cleanup")
struct PushTokenCleanupTests {

    private struct StepFailed: Error {}

    /// Fakes and a fresh defaults suite for one row.
    @MainActor
    private final class Harness {
        let suiteName = UUID().uuidString
        let defaults: UserDefaults
        let cleanup: PushTokenCleanup
        var events: [String] = []
        /// Stands in for the real session: `clearSession` flips it, and the
        /// fake unregister records what it saw.
        var signedIn = true
        var unregisterSawSignedIn: Bool?

        init(timeout: Duration = .seconds(3)) {
            defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)
            cleanup = PushTokenCleanup(defaults: defaults, timeout: timeout)
        }

        func tearDown() {
            defaults.removePersistentDomain(forName: suiteName)
        }

        func unregister() async throws {
            unregisterSawSignedIn = signedIn
            events.append("unregister")
        }

        func deleteToken() async throws {
            events.append("deleteToken")
        }

        func clearSession() {
            signedIn = false
            events.append("clear")
        }
    }

    // MARK: signOut

    @Test("a sign-out unregisters while still signed in, then clears, then deletes the token")
    func signOutOrder() async {
        let h = Harness()
        defer { h.tearDown() }

        await h.cleanup.signOut(
            unregister: { try await h.unregister() },
            deleteToken: { try await h.deleteToken() },
            clearSession: { h.clearSession() }
        )

        #expect(h.events == ["unregister", "clear", "deleteToken"])
        #expect(h.unregisterSawSignedIn == true)
        #expect(h.cleanup.isPending == false)
    }

    @Test("a failed unregister still clears the session and deletes the token, and leaves the retry marker")
    func unregisterThrows() async {
        let h = Harness()
        defer { h.tearDown() }

        await h.cleanup.signOut(
            unregister: {
                try await h.unregister()
                throw StepFailed()
            },
            deleteToken: { try await h.deleteToken() },
            clearSession: { h.clearSession() }
        )

        #expect(h.events == ["unregister", "clear", "deleteToken"])
        #expect(h.cleanup.isPending == true)
    }

    @Test("a hanging unregister is cut off at the timeout and logout still finishes")
    func unregisterTimesOut() async {
        let h = Harness(timeout: .milliseconds(200))
        defer { h.tearDown() }
        let clock = ContinuousClock()
        let started = clock.now

        await h.cleanup.signOut(
            unregister: {
                try await Task.sleep(for: .seconds(10))
                h.events.append("unregister")
            },
            deleteToken: { try await h.deleteToken() },
            clearSession: { h.clearSession() }
        )

        #expect(clock.now - started < .seconds(2))
        #expect(h.events == ["clear", "deleteToken"])
        #expect(h.cleanup.isPending == true)
    }

    @Test("a failed deleteToken leaves the retry marker")
    func deleteTokenThrows() async {
        let h = Harness()
        defer { h.tearDown() }

        await h.cleanup.signOut(
            unregister: { try await h.unregister() },
            deleteToken: {
                try await h.deleteToken()
                throw StepFailed()
            },
            clearSession: { h.clearSession() }
        )

        #expect(h.events == ["unregister", "clear", "deleteToken"])
        #expect(h.cleanup.isPending == true)
    }

    @Test("the retry marker is a plain Bool under pendingKey and nothing else is written")
    func markerIsOnlyABool() async {
        let h = Harness()
        defer { h.tearDown() }

        await h.cleanup.signOut(
            unregister: { throw StepFailed() },
            deleteToken: { try await h.deleteToken() },
            clearSession: { h.clearSession() }
        )

        let stored = h.defaults.persistentDomain(forName: h.suiteName) ?? [:]
        #expect(stored.keys.sorted() == [PushTokenCleanup.pendingKey])
        #expect(stored[PushTokenCleanup.pendingKey] as? Bool == true)
    }

    // MARK: forceSignOut (involuntary logout)

    @Test("an involuntary sign-out clears the session before returning, sends no unregister, then deletes the token in the background")
    func forceSignOutClearsFirstThenDeletesToken() async {
        let h = Harness()
        defer { h.tearDown() }

        h.cleanup.forceSignOut(
            deleteToken: { try await h.deleteToken() },
            clearSession: { h.clearSession() }
        )

        // The session is gone synchronously: the caller (a 401 refresh
        // failure, a rejected stored token, a suspension) must not wait on
        // the network before the shell can route to Login.
        #expect(h.events.first == "clear")
        #expect(!h.events.contains("unregister"))

        await waitUntil { h.events.contains("deleteToken") }
        #expect(h.events == ["clear", "deleteToken"])
        await waitUntil { h.cleanup.isPending == false }
        #expect(h.cleanup.isPending == false)
    }

    @Test("an involuntary sign-out whose deleteToken fails leaves the retry marker")
    func forceSignOutDeleteTokenThrows() async {
        let h = Harness()
        defer { h.tearDown() }

        h.cleanup.forceSignOut(
            deleteToken: {
                try await h.deleteToken()
                throw StepFailed()
            },
            clearSession: { h.clearSession() }
        )

        #expect(h.events.first == "clear")
        await waitUntil { h.events.contains("deleteToken") }
        #expect(h.events == ["clear", "deleteToken"])
        #expect(h.cleanup.isPending == true)
    }

    // MARK: retryIfPending (launch and login)

    @Test("a pending retry calls deleteToken once and clears the marker on success")
    func retryWithMarkerSucceeds() async {
        let h = Harness()
        defer { h.tearDown() }
        h.defaults.set(true, forKey: PushTokenCleanup.pendingKey)

        await h.cleanup.retryIfPending(deleteToken: { try await h.deleteToken() })

        #expect(h.events == ["deleteToken"])
        #expect(h.cleanup.isPending == false)
    }

    @Test("with no marker the retry is a no-op and deleteToken is not called")
    func retryWithoutMarkerIsNoOp() async {
        let h = Harness()
        defer { h.tearDown() }

        await h.cleanup.retryIfPending(deleteToken: { try await h.deleteToken() })

        #expect(h.events.isEmpty)
        #expect(h.cleanup.isPending == false)
    }

    @Test("a pending retry whose deleteToken fails keeps the marker for the next launch or login")
    func retryWithMarkerThrows() async {
        let h = Harness()
        defer { h.tearDown() }
        h.defaults.set(true, forKey: PushTokenCleanup.pendingKey)

        await h.cleanup.retryIfPending(deleteToken: {
            try await h.deleteToken()
            throw StepFailed()
        })

        #expect(h.events == ["deleteToken"])
        #expect(h.cleanup.isPending == true)
    }

    // MARK: Helpers

    /// Polls `condition` every 10 ms until it holds or `timeout` elapses.
    /// Used for the steps `forceSignOut` runs in a background Task after it
    /// has already returned.
    private func waitUntil(
        timeout: Duration = .seconds(1),
        _ condition: @MainActor () -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while !condition(), clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
