//
//  UpdateNotificationPreferencesRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `PATCH /notifications/preferences` — bulk update.
struct UpdateNotificationPreferencesRequest: Encodable {
    let preferences: [NotificationPreferenceInput]
}
