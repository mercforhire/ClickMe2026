//
//  NotificationCategory.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Notification category — matches the server's `notifications.category`
/// CHECK constraint. Per the Phase 17 taxonomy: six top-level buckets,
/// each with 1–7 sub-categories (surfaced only in the preferences
/// endpoint, not on notification rows themselves).
enum NotificationCategory: String, Decodable {
    /// Booking lifecycle — requests, confirmations, declines,
    /// cancellations, reschedules, expirations, refunds.
    case booking

    /// Session timing — reminder, no_show, ended.
    case session

    /// New messages when the recipient is not viewing the thread.
    case message

    /// Reviews received or nudges to leave one.
    case review

    /// Expert-only: payouts paid/failed, KYC actions needed.
    case payout

    /// Security + settings changes (password, deletion request).
    case account
}
