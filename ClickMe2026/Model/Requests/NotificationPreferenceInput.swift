//
//  NotificationPreferenceInput.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// One preference entry inside `UpdateNotificationPreferencesRequest.preferences`.
struct NotificationPreferenceInput: Encodable {
    let category: String
    let subCategory: String
    let pushEnabled: Bool?
    let emailEnabled: Bool?
    let inAppEnabled: Bool?
}
