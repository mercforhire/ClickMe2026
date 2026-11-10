//
//  ChatPresence.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which chat thread is on screen right now.
///
/// Read by the foreground push policy (`PushForegroundPolicy`) so a
/// `message` push for the thread the user is already reading shows no
/// banner (CHAT-09). This is not observable UI state: nothing renders
/// from it, so it is a plain main-actor holder rather than `@Observable`.
///
/// `ChatView` reports itself in `.onAppear` and `.onDisappear`. The same
/// rule as Android's `ChatSessionState.onThreadHidden`: a disappearing
/// chat clears the visible thread only when it is the one recorded, so a
/// second chat pushed on top of the first, then popped, leaves the first
/// thread marked again when its own `.onAppear` fires.
@MainActor
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
}
