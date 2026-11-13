//
//  AccountDeletionBlockerTests.swift
//  ClickMe2026Tests
//
//  SET-06 (D-10): the three self-delete 409 codes map to an iOS-owned blocker,
//  the "View My Bookings" action only appears when the blocker's side matches
//  the active mode, and the new client code decodes.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Account deletion blocker")
struct AccountDeletionBlockerTests {

    private static let everyMode = AppMode.allCases

    // MARK: - code mapping

    @Test("EXPERT_HAS_UPCOMING_BOOKINGS is the expert blocker")
    func expertCode() {
        #expect(AccountDeletionBlocker(code: .expertHasUpcomingBookings) == .expertUpcoming)
    }

    @Test("CLIENT_HAS_UPCOMING_BOOKINGS is the client blocker")
    func clientCode() {
        #expect(AccountDeletionBlocker(code: .clientHasUpcomingBookings) == .clientUpcoming)
    }

    @Test("SESSION_IN_PROGRESS is the session blocker")
    func sessionCode() {
        #expect(AccountDeletionBlocker(code: .sessionInProgress) == .sessionInProgress)
    }

    @Test("any other code or no code is not a blocker")
    func otherCodesAreNotBlockers() {
        #expect(AccountDeletionBlocker(code: .notFound) == nil)
        #expect(AccountDeletionBlocker(code: .forbidden) == nil)
        #expect(AccountDeletionBlocker(code: nil) == nil)
    }

    // MARK: - bookings action rule

    @Test("the expert blocker offers My Bookings only in Expert mode")
    func expertBlockerAction() {
        #expect(AccountDeletionBlocker.expertUpcoming.offersBookingsAction(in: .expert))
        #expect(!AccountDeletionBlocker.expertUpcoming.offersBookingsAction(in: .client))
    }

    @Test("the client blocker offers My Bookings only in Client mode")
    func clientBlockerAction() {
        #expect(AccountDeletionBlocker.clientUpcoming.offersBookingsAction(in: .client))
        #expect(!AccountDeletionBlocker.clientUpcoming.offersBookingsAction(in: .expert))
    }

    @Test("a session in progress offers My Bookings in both modes", arguments: AppMode.allCases)
    func sessionBlockerAction(mode: AppMode) {
        #expect(AccountDeletionBlocker.sessionInProgress.offersBookingsAction(in: mode))
    }

    // MARK: - copy

    @Test("the expert blocker in Client mode says to switch to Expert mode")
    func expertBlockerInClientMode() {
        let message = AccountDeletionBlocker.expertUpcoming.message(in: .client)
        #expect(message.contains("Switch to Expert mode"))
        #expect(message == "You have upcoming bookings as an expert. Switch to Expert mode to cancel or finish them, then try again.")
    }

    @Test("the expert blocker in Expert mode has no switch instruction")
    func expertBlockerInExpertMode() {
        let message = AccountDeletionBlocker.expertUpcoming.message(in: .expert)
        #expect(!message.contains("Switch to"))
        #expect(message == "You have upcoming bookings as an expert. Cancel or finish them, then try again.")
    }

    @Test("the client blocker in Expert mode says to switch to Client mode")
    func clientBlockerInExpertMode() {
        let message = AccountDeletionBlocker.clientUpcoming.message(in: .expert)
        #expect(message.contains("Switch to Client mode"))
        #expect(message == "You have upcoming sessions booked as a client. Switch to Client mode to cancel them, then try again.")
    }

    @Test("the client blocker in Client mode has no switch instruction")
    func clientBlockerInClientMode() {
        let message = AccountDeletionBlocker.clientUpcoming.message(in: .client)
        #expect(!message.contains("Switch to"))
        #expect(message == "You have upcoming sessions booked. Cancel them, then try again.")
    }

    @Test("the session blocker reads the same in both modes", arguments: AppMode.allCases)
    func sessionBlockerCopy(mode: AppMode) {
        #expect(AccountDeletionBlocker.sessionInProgress.message(in: mode)
            == "A session is in progress or starts within 15 minutes. Wait until it ends, then try again.")
    }

    @Test("the alert title and bookings button are the UI-SPEC strings")
    func fixedStrings() {
        #expect(AccountDeletionBlocker.title == "You can't delete your account yet")
        #expect(AccountDeletionBlocker.bookingsActionLabel == "View My Bookings")
    }

    // MARK: - decode

    @Test("CLIENT_HAS_UPCOMING_BOOKINGS decodes to the new ErrorCode case")
    func decodesClientCode() throws {
        let json = #"{"status":"error","code":"CLIENT_HAS_UPCOMING_BOOKINGS","message":"You have upcoming sessions."}"#
        let response = try JSONDecoder().decode(StandardErrorResponse.self, from: Data(json.utf8))

        #expect(response.code == .clientHasUpcomingBookings)
        #expect(AccountDeletionBlocker(code: response.code) == .clientUpcoming)
    }
}
