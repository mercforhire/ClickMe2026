//
//  NotificationPreferencesData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `GET /notifications/preferences`.
///
/// Server returns a flat list of preference rows — one per
/// `(category, sub_category)` pair. Clients group by `category` locally.
/// Rows for categories the client doesn't render (e.g. `promotions` on the
/// current settings screen) are simply ignored.
struct NotificationPreferencesData: Decodable {
    struct Preference: Decodable {
        let category: String
        let subCategory: String
        let pushEnabled: Bool
        let emailEnabled: Bool
        let inAppEnabled: Bool

        /// True when at least one channel is enabled — matches the master
        /// toggle UI, where "on" means "the user gets notified via some
        /// channel."
        var isAnyChannelEnabled: Bool {
            pushEnabled || emailEnabled || inAppEnabled
        }
    }

    let preferences: [Preference]
}
