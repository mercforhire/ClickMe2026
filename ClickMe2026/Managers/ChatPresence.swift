//
//  ChatPresence.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Observation

/// Which chat thread is on screen right now.
///
/// Observed by the Chats list (CHAT-07, D-12): a thread opened by any route
/// (list row, push tap, profile Message button, `HomeRoute.chat`) zeroes its
/// row, and when no thread is visible any more the list quietly re-fetches
/// `GET /chats`. Still read by the foreground push policy
/// (`PushForegroundPolicy`) so a `message` push for the thread the user is
/// already reading shows no banner (CHAT-09).
///
/// `ChatView` reports itself in `.onAppear` and `.onDisappear`. The same
/// rule as Android's `ChatSessionState.onThreadHidden`: a disappearing
/// chat clears the visible thread only when it is the one recorded, so a
/// second chat pushed on top of the first, then popped, leaves the first
/// thread marked again when its own `.onAppear` fires.
@MainActor
@Observable
final class ChatPresence {

    static let shared = ChatPresence()

    /// The thread currently on screen, or `nil` when no chat is open. A
    /// chat opened from a preview seed has no thread id and never sets it.
    private(set) var visibleThreadId: UUID?

    init() {}

    /// The chat for `threadId` is now on screen.
    func chatAppeared(threadId: UUID) {
        visibleThreadId = threadId
    }

    /// The chat for `threadId` left the screen. Clears the visible thread
    /// only when it is this one, so a stale disappear from a chat that was
    /// already replaced does not unmark the chat that is still showing.
    func chatDisappeared(threadId: UUID) {
        if visibleThreadId == threadId {
            visibleThreadId = nil
        }
    }

    /// Forgets the visible thread. Called when the session is cleared on
    /// logout, as Android's `ChatSessionState.clearSessionData` does, so a
    /// chat that was on screen for the old account cannot suppress the
    /// banner for a message push to whoever signs in next.
    func clearSessionData() {
        visibleThreadId = nil
    }
}
