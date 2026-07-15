//
//  DiscussionTopicEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct DiscussionTopicEntity: Codable {
    let id: UUID
    let expertId: UUID
    let title: String
    let durationMins: Int
    let description: String?
    let priceAmount: Int
    let priceCurrency: String?
    let isFree: Bool
    let sortOrder: Int
    let createdAt: Date?
}
