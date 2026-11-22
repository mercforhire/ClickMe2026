//
//  AccountDeletionCopyTests.swift
//  ClickMe2026Tests
//
//  SET-06 (D-08 to D-10): the Delete Account copy matches the locked strings and
//  makes no claim the backend does not keep (`accountCascade.purgeAndLockAccount`).
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Account deletion copy")
struct AccountDeletionCopyTests {

    private static let all: [(name: String, text: String)] = [
        ("permanence", AccountDeletionCopy.permanence),
        ("bookingsFirst", AccountDeletionCopy.bookingsFirst),
        ("deletedTitle", AccountDeletionCopy.deletedTitle),
        ("deletedBody", AccountDeletionCopy.deletedBody),
        ("keptAnonymizedTitle", AccountDeletionCopy.keptAnonymizedTitle),
        ("keptAnonymizedBody", AccountDeletionCopy.keptAnonymizedBody),
        ("keptTitle", AccountDeletionCopy.keptTitle),
        ("keptBody", AccountDeletionCopy.keptBody),
        ("savedCardsNote", AccountDeletionCopy.savedCardsNote)
    ]

    // MARK: - exact strings

    @Test("every string matches the locked copy exactly")
    func exactStrings() {
        #expect(AccountDeletionCopy.permanence == "Deleting your account is permanent and can't be undone.")
        #expect(AccountDeletionCopy.bookingsFirst == "Before you delete, cancel or finish any upcoming sessions. Requests you've sent that haven't been answered yet are cancelled for you, and any hold on your card is released.")
        #expect(AccountDeletionCopy.deletedTitle == "Deleted")
        #expect(AccountDeletionCopy.deletedBody == "Your name, photo, bio and location, your devices, your notifications and preferences, and your uploaded profile photos.")
        #expect(AccountDeletionCopy.keptAnonymizedTitle == "Kept without your personal details")
        #expect(AccountDeletionCopy.keptAnonymizedBody == "Your past bookings stay on record, shown as from \"Deleted user\". Your private notes on them are erased.")
        #expect(AccountDeletionCopy.keptTitle == "Kept")
        #expect(AccountDeletionCopy.keptBody == "Messages and reviews you've written stay visible to the other person, shown as from \"Deleted user\". Payment records are kept.")
        #expect(AccountDeletionCopy.savedCardsNote == "Cards you added to pay for sessions are not deleted with your account.")
    }

    // MARK: - no false claims

    @Test("no string says data is removed or makes a saved-card or payment-details claim")
    func noFalseClaims() {
        for (name, text) in Self.all {
            let lowered = text.lowercased()
            #expect(!lowered.contains("removed"), "\(name) must not say \"removed\"")
            #expect(!lowered.contains("saved card"), "\(name) must not make a saved-card claim")
            #expect(!lowered.contains("payment details"), "\(name) must not mention payment details")
        }
    }

    // MARK: - required facts

    @Test("kept body says messages and reviews stay visible, from Deleted user (D-09)")
    func keptBodyFacts() {
        #expect(AccountDeletionCopy.keptBody.contains("visible to the other person"))
        #expect(AccountDeletionCopy.keptBody.contains("Deleted user"))
    }

    @Test("anonymized body names Deleted user")
    func anonymizedBodyFacts() {
        #expect(AccountDeletionCopy.keptAnonymizedBody.contains("Deleted user"))
    }

    @Test("bookings-first line tells the user about upcoming sessions (D-10)")
    func bookingsFirstFacts() {
        #expect(AccountDeletionCopy.bookingsFirst.contains("upcoming"))
    }
}
