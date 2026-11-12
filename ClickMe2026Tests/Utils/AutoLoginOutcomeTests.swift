//
//  AutoLoginOutcomeTests.swift
//  ClickMe2026Tests
//
//  D-13: a cold launch whose /me refresh meets a 403 ACCOUNT_SUSPENDED ends
//  signed out, so the splash routes to Login and no home shell appears. A
//  transient failure still keeps the stored token (offline tolerance).
//

import Testing
@testable import ClickMe2026

@MainActor
@Suite("Auto-login outcome")
struct AutoLoginOutcomeTests {

    private static let everyResult: [AutoLoginOutcome.RefreshResult] = [
        .succeeded, .authRejected, .suspended, .transientFailure
    ]

    @Test("no stored token is signed out whatever the refresh result")
    func noTokenIsSignedOut() {
        for result in Self.everyResult {
            #expect(AutoLoginOutcome.resolve(hadStoredToken: false, refresh: result) == .signedOut)
        }
    }

    @Test("a successful refresh stays signed in")
    func succeededIsSignedIn() {
        #expect(AutoLoginOutcome.resolve(hadStoredToken: true, refresh: .succeeded) == .signedIn)
    }

    @Test("a transient failure keeps the session")
    func transientFailureIsSignedIn() {
        #expect(AutoLoginOutcome.resolve(hadStoredToken: true, refresh: .transientFailure) == .signedIn)
    }

    @Test("a rejected token is signed out")
    func authRejectedIsSignedOut() {
        #expect(AutoLoginOutcome.resolve(hadStoredToken: true, refresh: .authRejected) == .signedOut)
    }

    @Test("a suspension is signed out, so no home shell is shown")
    func suspendedIsSignedOut() {
        #expect(AutoLoginOutcome.resolve(hadStoredToken: true, refresh: .suspended) == .signedOut)
    }
}
