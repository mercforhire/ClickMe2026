//
//  PushTokenCleanupTests.swift
//  ClickMe2026Tests
//
//  PUSH-04: a user logout sends the server DELETE while the session is
//  still signed in, then deletes the FCM token, then clears the session
//  (Android `UserManager.logout()` order, user decision 2026-11-10 in quick
//  261110-mmr). Each network step is cut off at the timeout and a failed or
//  timed-out step never stops logout; it leaves the deleteToken-only retry
//  marker (D-17, D-18).
//
//  WR-02: every `deleteToken` runs on one serialized lane, shared by
//  `signOut`, `forceSignOut` and `retryIfPending`, and the retry awaits the
//  run in flight before deciding whether it still owes one. Because login
//  and signup await that retry before registering, a sign-in that lands
//  while an involuntary logout's background `deleteToken` is still running
//  waits for it (bounded) and the old cleanup can never invalidate the
//  token the new account is about to bind.
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
        /// fake unregister and deleteToken record what they saw.
        var signedIn = true
        var unregisterSawSignedIn: Bool?
        var deleteTokenSawSignedIn: Bool?
        /// How many deleteToken fakes are running right now, and the most
        /// that ever ran at once. The lane must keep the maximum at 1.
        var concurrentDeleteTokens = 0
        var maxConcurrentDeleteTokens = 0

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
            deleteTokenSawSignedIn = signedIn
            events.append("deleteToken")
        }

        func clearSession() {
            signedIn = false
            events.append("clear")
        }

        /// A deleteToken fake that takes `duration`, appends `label` when it
        /// finishes and optionally throws. Tracks how many such fakes
        /// overlap so a row can assert the lane never runs two at once.
        func slowDeleteToken(
            _ label: String,
            taking duration: Duration,
            throwing: Bool = false
        ) async throws {
            concurrentDeleteTokens += 1
            maxConcurrentDeleteTokens = max(maxConcurrentDeleteTokens, concurrentDeleteTokens)
            defer { concurrentDeleteTokens -= 1 }
            try await Task.sleep(for: duration)
            events.append(label)
            if throwing { throw StepFailed() }
        }
    }

    // MARK: signOut

    @Test("a sign-out unregisters while still signed in, deletes the token while still signed in, then clears the session")
    func signOutOrder() async {
        let h = Harness()
        defer { h.tearDown() }

        await h.cleanup.signOut(
            unregister: { try await h.unregister() },
            deleteToken: { try await h.deleteToken() },
            clearSession: { h.clearSession() }
        )

        #expect(h.events == ["unregister", "deleteToken", "clear"])
        #expect(h.unregisterSawSignedIn == true)
        #expect(h.deleteTokenSawSignedIn == true)
        #expect(h.signedIn == false)
        #expect(h.cleanup.isPending == false)
    }

    @Test("a failed unregister still deletes the token and clears the session, and leaves the retry marker")
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

        #expect(h.events == ["unregister", "deleteToken", "clear"])
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
        #expect(h.events == ["deleteToken", "clear"])
        #expect(h.cleanup.isPending == true)
    }

    @Test("a failed deleteToken still clears the session and leaves the retry marker")
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

        #expect(h.events == ["unregister", "deleteToken", "clear"])
        #expect(h.cleanup.isPending == true)
    }

    @Test("a hanging deleteToken is cut off at the timeout, so logout still clears the session within the cap and leaves the retry marker")
    func aHungDeleteTokenStillFinishesLogoutWithinTheCap() async {
        let h = Harness(timeout: .milliseconds(200))
        defer { h.tearDown() }
        let clock = ContinuousClock()
        let started = clock.now

        await h.cleanup.signOut(
            unregister: { try await h.unregister() },
            deleteToken: {
                try await Task.sleep(for: .seconds(10))
                h.events.append("deleteToken")
            },
            clearSession: { h.clearSession() }
        )

        #expect(clock.now - started < .seconds(2))
        #expect(h.events == ["unregister", "clear"])
        #expect(h.signedIn == false)
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

    @Test("after a completed logout the next sign-in's retry is a no-op: nothing is owed and no second deleteToken runs")
    func aCompletedLogoutLeavesNothingForTheNextSignInToWaitOn() async {
        let h = Harness()
        defer { h.tearDown() }

        await h.cleanup.signOut(
            unregister: { try await h.unregister() },
            deleteToken: { try await h.deleteToken() },
            clearSession: { h.clearSession() }
        )
        await h.cleanup.retryIfPending(deleteToken: { h.events.append("retryDeleteToken") })

        #expect(h.events == ["unregister", "deleteToken", "clear"])
        #expect(h.cleanup.isPending == false)
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

    // MARK: One deleteToken lane (WR-02)

    @Test("a sign-in right after an involuntary logout waits for its background deleteToken instead of starting a second one")
    func retryWaitsForAnInvoluntaryLogoutsBackgroundDeleteToken() async {
        let h = Harness()
        defer { h.tearDown() }

        h.cleanup.forceSignOut(
            deleteToken: { try await h.slowDeleteToken("deleteToken", taking: .milliseconds(200)) },
            clearSession: { h.clearSession() }
        )
        // The next account's login awaits this retry before registering.
        await h.cleanup.retryIfPending(deleteToken: {
            try await h.slowDeleteToken("retryDeleteToken", taking: .zero)
        })
        h.events.append("retryReturned")

        #expect(h.events == ["clear", "deleteToken", "retryReturned"])
        #expect(h.maxConcurrentDeleteTokens == 1)
        #expect(h.cleanup.isPending == false)
    }

    @Test("when the in-flight deleteToken fails, the retry runs its own only after it has finished, never alongside it")
    func retryAfterAFailedInFlightDeleteTokenRunsOnceItHasFinished() async {
        let h = Harness()
        defer { h.tearDown() }

        h.cleanup.forceSignOut(
            deleteToken: {
                try await h.slowDeleteToken("deleteToken", taking: .milliseconds(200), throwing: true)
            },
            clearSession: { h.clearSession() }
        )
        await h.cleanup.retryIfPending(deleteToken: {
            try await h.slowDeleteToken("retryDeleteToken", taking: .zero)
        })
        h.events.append("retryReturned")

        #expect(h.events == ["clear", "deleteToken", "retryDeleteToken", "retryReturned"])
        #expect(h.maxConcurrentDeleteTokens == 1)
        #expect(h.cleanup.isPending == false)
    }

    @Test("a hanging deleteToken never holds the next sign-in past the timeout")
    func aHangingDeleteTokenNeverHoldsTheNextSignInPastTheTimeout() async {
        let h = Harness(timeout: .milliseconds(200))
        defer { h.tearDown() }
        let clock = ContinuousClock()

        h.cleanup.forceSignOut(
            deleteToken: { try await h.slowDeleteToken("deleteToken", taking: .seconds(10)) },
            clearSession: { h.clearSession() }
        )
        let started = clock.now
        await h.cleanup.retryIfPending(deleteToken: {
            try await h.slowDeleteToken("retryDeleteToken", taking: .zero)
        })

        // The hung run was counted as failed at the cap, so the retry ran
        // its own deleteToken, which succeeded and cleared the marker.
        #expect(clock.now - started < .seconds(2))
        #expect(h.events == ["clear", "retryDeleteToken"])
        #expect(h.cleanup.isPending == false)
    }

    @Test("an involuntary logout during a user logout never runs its deleteToken alongside the user logout's")
    func userAndInvoluntaryDeleteTokensNeverOverlap() async {
        let h = Harness()
        defer { h.tearDown() }

        let signOut = Task { @MainActor in
            await h.cleanup.signOut(
                unregister: { try await h.unregister() },
                deleteToken: { try await h.slowDeleteToken("deleteToken", taking: .milliseconds(200)) },
                clearSession: { h.clearSession() }
            )
        }
        await waitUntil { h.events.contains("unregister") }
        // A suspension or rejected token lands while the user logout's
        // deleteToken is still running.
        h.cleanup.forceSignOut(
            deleteToken: { try await h.slowDeleteToken("forceDeleteToken", taking: .zero) },
            clearSession: { h.clearSession() }
        )
        await signOut.value
        await waitUntil { h.events.contains("forceDeleteToken") }

        #expect(h.maxConcurrentDeleteTokens == 1)
        #expect(h.events.first == "unregister")
        let userIndex = h.events.firstIndex(of: "deleteToken")
        let forceIndex = h.events.firstIndex(of: "forceDeleteToken")
        #expect(userIndex != nil && forceIndex != nil && userIndex! < forceIndex!)
        #expect(h.events.filter { $0 == "clear" }.count == 2)
        await waitUntil { h.cleanup.isPending == false }
        #expect(h.cleanup.isPending == false)
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
