//
//  FAQCategoryEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct FAQCategoryEntity: Codable {
    let id: UUID
    let title: String
    let iconUrl: String?
    let displayOrder: Int
    let createdAt: Date
}
