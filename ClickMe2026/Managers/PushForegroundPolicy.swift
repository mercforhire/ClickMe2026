//
//  PushForegroundPolicy.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import UserNotifications

/// Decides how a push that arrives while the app is frontmost is presented.
///
/// Pure: the decision depends only on the parsed event and on which chat
/// thread is on screen, so it is unit-tested without a notification
/// center. The caller (`ClickMe2026AppDelegate.willPresent`) reads the
/// visible thread from `ChatPresence.shared` on the main actor.
enum PushForegroundPolicy {

    /// The normal presentation: banner, Notification Center entry, sound
    /// and badge. iOS 14+ uses `.banner + .list` in place of `.alert`.
    static let fullOptions: UNNotificationPresentationOptions = [.banner, .list, .sound, .badge]

    /// Presentation options for `event` while `visibleChatThreadId` is the
    /// chat on screen (or `nil` when no chat is open).
    ///
    /// Returns no options at all, so no banner, no sound and no Notification
    /// Center entry, only for a `message` push whose `thread_id` is the
    /// thread the user is already reading (CHAT-09). Every other push, and
    /// every chat push for another thread or with no thread id, presents
    /// normally. Nothing here decides whether the notifications list
    /// refreshes; `PushRouter.handleForegroundArrival` runs regardless.
    static func options(
        for event: PushEvent,
        visibleChatThreadId: UUID?
    ) -> UNNotificationPresentationOptions {
        guard event.category == "message",
              let threadId = event.threadId,
              let visibleChatThreadId,
              threadId == visibleChatThreadId
        else {
            return fullOptions
        }
        return []
    }
}
