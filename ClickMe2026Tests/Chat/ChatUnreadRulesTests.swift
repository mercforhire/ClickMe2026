//
//  ChatUnreadRulesTests.swift
//  ClickMe2026Tests
//
//  CHAT-07 (D-14): the unread pill text, the VoiceOver clause and label, and the
//  counting rules, at the boundaries 0, 1, 99 and 100. Pure: no network and no
//  view model.
//

import Testing
@testable import ClickMe2026

@Suite("ChatUnreadRules")
struct ChatUnreadRulesTests {

    @Test("badge label is hidden at zero and below, the number to 99, and 99+ above")
    func badgeLabelBoundaries() {
        #expect(ChatUnreadRules.badgeLabel(count: -1) == nil)
        #expect(ChatUnreadRules.badgeLabel(count: 0) == nil)
        #expect(ChatUnreadRules.badgeLabel(count: 1) == "1")
        #expect(ChatUnreadRules.badgeLabel(count: 99) == "99")
        #expect(ChatUnreadRules.badgeLabel(count: 100) == "99+")
        #expect(ChatUnreadRules.badgeLabel(count: 250) == "99+")
    }

    @Test("unread clause is singular at 1, plural to 99, and capped above")
    func unreadClauseBoundaries() {
        #expect(ChatUnreadRules.unreadClause(count: 0) == nil)
        #expect(ChatUnreadRules.unreadClause(count: -3) == nil)
        #expect(ChatUnreadRules.unreadClause(count: 1) == "1 unread message")
        #expect(ChatUnreadRules.unreadClause(count: 2) == "2 unread messages")
        #expect(ChatUnreadRules.unreadClause(count: 99) == "99 unread messages")
        #expect(ChatUnreadRules.unreadClause(count: 100) == "More than 99 unread messages")
    }

    @Test("row label carries the unread clause between name and preview")
    func rowLabelWithCount() {
        let label = ChatUnreadRules.rowAccessibilityLabel(
            name: "Alice", count: 2, preview: "See you soon", time: "10:23 AM", isOnline: false
        )
        #expect(label == "Alice. 2 unread messages. See you soon. 10:23 AM")
    }

    @Test("row label omits the unread clause and its period at zero")
    func rowLabelWithoutCount() {
        let label = ChatUnreadRules.rowAccessibilityLabel(
            name: "Alice", count: 0, preview: "See you soon", time: "10:23 AM", isOnline: false
        )
        #expect(label == "Alice. See you soon. 10:23 AM")
    }

    @Test("row label appends Online. when the peer is online")
    func rowLabelOnline() {
        let label = ChatUnreadRules.rowAccessibilityLabel(
            name: "Alice", count: 1, preview: "Hi", time: "Yesterday", isOnline: true
        )
        #expect(label == "Alice. 1 unread message. Hi. Yesterday. Online.")
    }

    @Test("a peer message adds one and opening a thread resets to zero")
    func countingRules() {
        #expect(ChatUnreadRules.afterPeerMessage(count: 5) == 6)
        #expect(ChatUnreadRules.afterOpen == 0)
    }
}
