//
//  FAQArticleEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct FAQArticleEntity: Codable {
    let id: UUID
    let categoryId: UUID
    let question: String
    let contentMd: String
    let snippet: String?
    let viewCount: Int
    let isFeatured: Bool
    let relatedIds: [UUID]?
    let lastUpdated: Date
    let createdAt: Date
}
