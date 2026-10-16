//
//  PushEvent.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Wire-shape of a push payload's `data` dictionary as emitted by the
/// backend. Every notification carries `category` + `sub_category` plus
/// entity IDs relevant to that category — there's no explicit
/// `deep_link` field, so the client derives the route from the tuple.
///
/// The dictionary values arrive as `Any` (from `UNNotificationContent`
/// or FCM), so we decode defensively rather than through Codable.
struct PushEvent {

    /// Coarse bucket. Matches `NotificationCategory` rawValues.
    let category: String
    /// Fine-grained event within the category (e.g. `"reschedules"`,
    /// `"new_message"`, `"reminder"`). May be nil for older payloads.
    let subCategory: String?

    /// Entity IDs surfaced in the payload. Any / all may be nil
    /// depending on the category.
    let bookingId: UUID?
    let threadId: UUID?
    let reviewId: UUID?
    let payoutId: UUID?

    /// Raw payload for anything the typed fields don't cover — kept for
    /// future extension without a decoder change.
    let raw: [String: Any]

    /// Parse the `userInfo` dictionary from a `UNNotificationContent`.
    /// Returns nil when there's no recognisable `category` field, so
    /// the caller can early-out on generic pushes.
    init?(userInfo: [AnyHashable: Any]) {
        // FCM payloads nest app fields under `data`; APNs custom payloads
        // may put them at the root. Try both.
        let data: [String: Any] = {
            if let nested = userInfo["data"] as? [String: Any] { return nested }
            var flattened: [String: Any] = [:]
            for (key, value) in userInfo {
                if let key = key as? String { flattened[key] = value }
            }
            return flattened
        }()

        // Backend uses two overlapping payload schemas depending on the
        // emitter path:
        //  1. `category` + `sub_category` — the documented taxonomy
        //     (booking, session, review, payout, account).
        //  2. `event_type` — used at least by chat pushes
        //     (`NEW_MESSAGE`), no `category` field present.
        // Try (1) first, then fall back to a lookup that synthesises
        // (category, sub_category) from `event_type` values we've
        // observed on the wire. Extend the switch as other push types
        // surface with the second schema.
        let resolvedCategory: String
        let resolvedSubCategory: String?
        if let cat = data["category"] as? String, !cat.isEmpty {
            resolvedCategory = cat
            resolvedSubCategory = data["sub_category"] as? String
        } else if let eventType = data["event_type"] as? String {
            switch eventType.uppercased() {
            case "NEW_MESSAGE":
                resolvedCategory = "message"
                resolvedSubCategory = "new_message"
            case "NEW_BOOKING_REQUEST", "BOOKING_REQUEST", "REQUEST_CREATED":
                // Common naming variants — backend hasn't committed
                // to one string yet. Match any of them so we route
                // even if the wire label drifts.
                resolvedCategory = "booking"
                resolvedSubCategory = "requests"
            default:
                return nil
            }
        } else {
            return nil
        }

        self.category = resolvedCategory
        self.subCategory = resolvedSubCategory
        self.bookingId = (data["booking_id"] as? String).flatMap { UUID(uuidString: $0) }
        self.threadId = (data["thread_id"] as? String).flatMap { UUID(uuidString: $0) }
        self.reviewId = (data["review_id"] as? String).flatMap { UUID(uuidString: $0) }
        self.payoutId = (data["payout_id"] as? String).flatMap { UUID(uuidString: $0) }
        self.raw = data
    }
}
