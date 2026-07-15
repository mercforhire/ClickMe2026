//
//  NotificationCategory.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Notification category — values from the `notifications.category` CHECK constraint.
enum NotificationCategory: String, Decodable {
    case messages
    case bookings
    case promotions
}
