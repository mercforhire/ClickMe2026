//
//  NotificationItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single notification row returned by `GET /notifications`.
///
/// Per Phase 17: notifications are time-expiring rather than read-tracked.
/// The server sets `expiresAt` based on category (session: 24h, review:
/// 30d, etc.) and prunes past-expired rows in a daily job — there is no
/// `is_read` flag and no unread-count on the endpoint.
struct NotificationItem: Decodable {
    let id: UUID
    let userId: UUID
    let category: NotificationCategory
    let title: String
    let body: String
    /// Arbitrary payload the server attaches — typically carries the
    /// entity id needed to route on tap (e.g. `{"booking_id": "..."}`).
    let metaData: JSONValue?
    /// When the server will prune this row. Rows returned in a live
    /// response are guaranteed to still be within their TTL.
    let expiresAt: Date
    /// True for `payout` rows and other expert-scoped notifications.
    /// Currently unused client-side (the server already omits these
    /// rows for client-only accounts) — kept for defense-in-depth so
    /// a client mode session doesn't render an expert-scoped alert if
    /// role gating drifts.
    let isExpertOnly: Bool
    let createdAt: Date
}
