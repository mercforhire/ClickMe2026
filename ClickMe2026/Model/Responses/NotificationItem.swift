//
//  NotificationItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Full notifications row returned by `GET /notifications`.
struct NotificationItem: Decodable {
    enum Category: String, Decodable {
        case messages
        case bookings
        case promotions
    }

    let id: UUID
    let userId: UUID
    let category: Category
    let title: String
    let body: String
    let deepLink: String?
    let metaData: JSONValue?
    let isRead: Bool
    let createdAt: Date
}
