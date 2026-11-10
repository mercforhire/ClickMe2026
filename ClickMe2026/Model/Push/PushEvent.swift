//
//  PushEvent.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The routing facts a push payload carries, read from its `data`
/// dictionary. There is no `deep_link` field: the client derives the
/// screen from `(category, subCategory)` plus the entity ids, and the
/// mode from `targetRole`.
///
/// iOS reads `route_category` and `route_sub_category`, never `category`
/// or `sub_category`. The backend keeps `category` off iOS tokens while
/// App Store build 6 is in use, because build 6 routed on it and landed
/// on an unregistered route (CR-01, backend hotfix 215adcb). Contract:
/// backend `docs/ios/PUSH-ROUTING.md`.
///
/// The dictionary values arrive as `Any` (from `UNNotificationContent`
/// or FCM), so parsing is defensive rather than through Codable, and it
/// never fails: a payload with nothing recognisable yields a `nil`
/// category, which the router turns into the notifications list.
struct PushEvent {

    /// Coarse bucket (`booking`, `session`, `message`, `review`, `payout`,
    /// `account`), trimmed and lowercased. `nil` when the payload has no
    /// `route_category` and no `event_type` the fallback table knows; the
    /// caller then opens the notifications list (PUSH-01).
    let category: String?
    /// Event within the category (for example `requests`, `new_message`),
    /// trimmed and lowercased. `nil` when absent or empty.
    let subCategory: String?
    /// The mode the push was meant for, from `target_role`. Only `client`
    /// and `expert` are read; anything else counts as absent, which keeps
    /// the current mode (D-02).
    let targetRole: AppMode?

    /// Entity ids surfaced in the payload. Each is `nil` unless the value
    /// parses as a UUID, so a crafted or malformed id never reaches a route.
    let bookingId: UUID?
    let threadId: UUID?
    let reviewId: UUID?
    let payoutId: UUID?

    /// Legacy `event_type` discriminators mapped to `(category, subCategory)`
    /// for payloads with no `route_category` (D-16). Copied from Android's
    /// `PushEvent.kt` so both clients route the same senders the same way.
    /// Keys are matched against the uppercased, trimmed `event_type`.
    private static let eventTypeFallback: [String: (category: String, subCategory: String)] = [
        "NEW_MESSAGE": ("message", "new_message"),
        "NEW_BOOKING_REQUEST": ("booking", "requests"),
        "BOOKING_REQUEST": ("booking", "requests"),
        "REQUEST_CREATED": ("booking", "requests"),
        "BOOKING_CONFIRMED": ("booking", "confirmations"),
        "BOOKING_DECLINED": ("booking", "declines"),
        "BOOKING_CANCELLED": ("booking", "cancellations"),
        "BOOKING_RESCHEDULED": ("booking", "reschedules"),
        "BOOKING_EXPIRED": ("booking", "expirations"),
        "BOOKING_COMPLETED": ("session", "ended"),
        "REVIEW_SUBMITTED": ("review", "received"),
        "REFUND_ISSUED": ("booking", "refunds"),
        "PAYMENT_ACTION_REQUIRED": ("booking", "payment_actions"),
        "PAYOUT_PAID": ("payout", "paid"),
        "PAYOUT_FAILED": ("payout", "failed"),
        "KYC_ACTION_REQUIRED": ("payout", "kyc_action"),
        "DISPUTE_CREATED": ("payout", "dispute"),
        "PASSWORD_CHANGED": ("account", "password_changed"),
        "DELETION_REQUESTED": ("account", "deletion_requested"),
    ]

    /// Parse the `userInfo` dictionary from a `UNNotificationContent`.
    ///
    /// FCM payloads nest the app fields under `data`; APNs custom payloads
    /// may put them at the root. When both exist, the nested dictionary is
    /// read. `route_category` wins over `event_type` whenever it is
    /// non-empty; the fallback table is consulted only when it is missing
    /// or blank.
    init(userInfo: [AnyHashable: Any]) {
        let data: [String: Any] = {
            if let nested = userInfo["data"] as? [String: Any] { return nested }
            var flattened: [String: Any] = [:]
            for (key, value) in userInfo {
                if let key = key as? String { flattened[key] = value }
            }
            return flattened
        }()

        if let routeCategory = Self.normalized(data["route_category"]) {
            category = routeCategory
            subCategory = Self.normalized(data["route_sub_category"])
        } else if let eventType = Self.normalized(data["event_type"]),
                  let fallback = Self.eventTypeFallback[eventType.uppercased()]
        {
            category = fallback.category
            subCategory = fallback.subCategory
        } else {
            category = nil
            subCategory = nil
        }

        switch Self.normalized(data["target_role"]) {
        case "client": targetRole = .client
        case "expert": targetRole = .expert
        default: targetRole = nil
        }

        bookingId = Self.uuid(data["booking_id"])
        threadId = Self.uuid(data["thread_id"])
        reviewId = Self.uuid(data["review_id"])
        payoutId = Self.uuid(data["payout_id"])
    }

    /// Trimmed and lowercased string value; `nil` when the value is not a
    /// string or is empty after trimming.
    private static func normalized(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? nil : trimmed
    }

    /// A string value parsed as a UUID (any case); `nil` otherwise.
    private static func uuid(_ value: Any?) -> UUID? {
        guard let string = value as? String else { return nil }
        return UUID(uuidString: string.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
