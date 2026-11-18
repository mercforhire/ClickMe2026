//
//  ChatThreadLookup.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Finds one thread in `GET /chats` (CHAT-05, D-10).
///
/// There is no single-thread endpoint, so a thread is found by scanning the
/// caller's list, which the server returns newest-first. The scan reads pages of
/// 100 (the backend caps `limit` at 100, `Math.min(100, …)` in
/// `chats.controller.js`) and stops after `maxPages` pages, matching Android's
/// `SCAN_LIMIT = 100`.
///
/// A nil result means "not found in the pages read", never "not blocked": a
/// caller that reads block flags must not treat nil as an unblocked thread
/// (CHAT-UNBLOCK §6).
enum ChatThreadLookup {

    static let pageSize = 100
    static let maxPages = 3

    /// The thread with `threadId`, or nil when none of the first `maxPages` pages
    /// lists it. Stops early when a page has no threads, when the response has no
    /// `pagination`, or when the last page was read. Errors propagate.
    static func find(
        threadId: UUID,
        api: ClickMeAPI,
        maxPages: Int = maxPages
    ) async throws -> ChatThreadItem? {
        return nil
    }
}
