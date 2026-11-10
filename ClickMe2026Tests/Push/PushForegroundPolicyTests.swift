//
//  PushForegroundPolicyTests.swift
//  ClickMe2026Tests
//
//  CHAT-09: a foreground chat push for the thread already on screen is
//  presented with no options (no banner, no sound, no Notification Center
//  entry); every other push keeps the full presentation.
//

import Foundation
import Testing
import UserNotifications
@testable import ClickMe2026

@MainActor
@Suite("Push foreground policy")
struct PushForegroundPolicyTests {

    private static let threadT = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let threadU = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    private static let full: UNNotificationPresentationOptions = [.banner, .list, .sound, .badge]

    private static func messagePush(threadId: UUID?) -> PushEvent {
        var data: [AnyHashable: Any] = [
            "route_category": "message",
            "route_sub_category": "new_message",
        ]
        if let threadId { data["thread_id"] = threadId.uuidString }
        return PushEvent(userInfo: data)
    }

    // MARK: Policy

    @Test("fullOptions is banner, list, sound and badge")
    func fullOptionsValue() {
        #expect(PushForegroundPolicy.fullOptions == Self.full)
    }

    @Test("a message push for the chat on screen presents nothing")
    func sameThreadSuppressed() {
        let options = PushForegroundPolicy.options(
            for: Self.messagePush(threadId: Self.threadT),
            visibleChatThreadId: Self.threadT
        )
        #expect(options == [])
    }

    @Test("a message push for another chat presents normally")
    func otherThreadPresents() {
        let options = PushForegroundPolicy.options(
            for: Self.messagePush(threadId: Self.threadT),
            visibleChatThreadId: Self.threadU
        )
        #expect(options == Self.full)
    }

    @Test("a message push with no chat on screen presents normally")
    func noVisibleChatPresents() {
        let options = PushForegroundPolicy.options(
            for: Self.messagePush(threadId: Self.threadT),
            visibleChatThreadId: nil
        )
        #expect(options == Self.full)
    }

    @Test("a message push with no thread id never suppresses, even with a chat open")
    func noThreadIdPresents() {
        let options = PushForegroundPolicy.options(
            for: Self.messagePush(threadId: nil),
            visibleChatThreadId: Self.threadT
        )
        #expect(options == Self.full)
    }

    @Test("a non-chat push presents normally even when its thread_id matches the open chat")
    func nonChatPushPresents() {
        let event = PushEvent(userInfo: [
            "route_category": "booking",
            "route_sub_category": "confirmations",
            "thread_id": Self.threadT.uuidString,
        ])
        let options = PushForegroundPolicy.options(
            for: event,
            visibleChatThreadId: Self.threadT
        )
        #expect(options == Self.full)
    }

    @Test("a chat push routed through the event_type fallback is still a message push")
    func eventTypeFallbackSuppressed() {
        let event = PushEvent(userInfo: [
            "event_type": "NEW_MESSAGE",
            "thread_id": Self.threadT.uuidString,
        ])
        let options = PushForegroundPolicy.options(
            for: event,
            visibleChatThreadId: Self.threadT
        )
        #expect(options == [])
    }
}
