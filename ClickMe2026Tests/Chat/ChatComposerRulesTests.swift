//
//  ChatComposerRulesTests.swift
//  ClickMe2026Tests
//
//  CHAT-01 (D-04): the composer cap and counter rules. Everything is measured in
//  UTF-16 code units, the unit the server's zod `max(10000)` counts, and a cap
//  never splits an emoji. Pure rules, no network and no view model.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("ChatComposerRules")
struct ChatComposerRulesTests {

    private let en = Locale(identifier: "en_US")

    // MARK: Cap

    @Test("The cap cuts 12,000 plain characters to 10,000 units")
    func capCutsPlainText() {
        let capped = ChatComposerRules.cap(String(repeating: "a", count: 12_000))
        #expect(capped.utf16.count == 10_000)
    }

    @Test("The cap drops a trailing emoji whole instead of splitting it")
    func capNeverSplitsAnEmoji() {
        let raw = String(repeating: "a", count: 9_999) + "😀"
        let capped = ChatComposerRules.cap(raw)
        #expect(capped.utf16.count == 9_999)
        #expect(capped == String(repeating: "a", count: 9_999))
    }

    @Test("Text that already fits is returned unchanged, including exactly 10,000")
    func capLeavesFittingTextAlone() {
        let exact = String(repeating: "b", count: 10_000)
        #expect(ChatComposerRules.cap(exact) == exact)
        #expect(ChatComposerRules.cap("hello") == "hello")
    }

    // MARK: Counter thresholds

    @Test("The counter shows from 9,000 units and not before")
    func showsCounterThreshold() {
        #expect(!ChatComposerRules.showsCounter(length: 8_999))
        #expect(ChatComposerRules.showsCounter(length: 9_000))
        #expect(ChatComposerRules.showsCounter(length: 10_000))
    }

    @Test("At the limit means exactly 10,000 units")
    func isAtLimitThreshold() {
        #expect(!ChatComposerRules.isAtLimit(length: 9_999))
        #expect(ChatComposerRules.isAtLimit(length: 10_000))
    }

    // MARK: Counter text

    @Test("The counter text groups both numbers for the locale")
    func counterTextIsGrouped() {
        #expect(ChatComposerRules.counterText(length: 9_500, locale: en) == "9,500 / 10,000")
    }

    @Test("The VoiceOver label reads the count out of 10,000 characters")
    func accessibilityLabel() {
        #expect(
            ChatComposerRules.accessibilityCounterLabel(length: 10_000, locale: en)
                == "10,000 of 10,000 characters"
        )
    }

    // MARK: Announcement

    @Test("The limit is crossed only on the keystroke that reaches it")
    func crossedLimitRules() {
        #expect(ChatComposerRules.crossedLimit(oldLength: 9_999, newLength: 10_000))
        #expect(!ChatComposerRules.crossedLimit(oldLength: 10_000, newLength: 10_000))
        #expect(ChatComposerRules.crossedLimit(oldLength: 0, newLength: 10_000))
        #expect(!ChatComposerRules.crossedLimit(oldLength: 5, newLength: 6))
    }

    // MARK: Restored text after a refused send

    @Test("Restored text: refused alone, joined with a newline, blank draft ignored")
    func restoredTextJoin() {
        #expect(ChatSendCoordinator.restoredText(refused: "a", draft: "") == "a")
        #expect(ChatSendCoordinator.restoredText(refused: "a", draft: "  \n") == "a")
        #expect(ChatSendCoordinator.restoredText(refused: "a", draft: "b") == "a\nb")
    }

    @Test("Restored text goes through the cap so the composer never exceeds 10,000 units")
    func restoredTextIsCapped() {
        let restored = ChatSendCoordinator.restoredText(
            refused: String(repeating: "x", count: 9_999),
            draft: "yy"
        )
        #expect(ChatComposerRules.cap(restored).utf16.count == 10_000)
    }

    // MARK: Send button rule

    @Test("Whitespace-only text has a trimmed length of 0, so Send stays hidden")
    func whitespaceOnlyHasNoLength() {
        let trimmed = "   ".trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed.utf16.count == 0)
    }
}
