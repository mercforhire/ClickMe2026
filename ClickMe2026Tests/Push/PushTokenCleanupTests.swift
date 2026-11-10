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
}
