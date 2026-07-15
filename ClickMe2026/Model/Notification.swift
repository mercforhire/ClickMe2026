//
//  NotificationEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct NotificationEntity: Codable {
    let id: UUID
    let userId: UUID
    let category: String
    let title: String
    let body: String
    let deepLink: String?
    let metaData: JSONValue?
    let isRead: Bool
    let createdAt: Date
}
