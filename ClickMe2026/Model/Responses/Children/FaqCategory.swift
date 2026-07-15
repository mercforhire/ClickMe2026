//
//  FaqCategory.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// FAQ category with enriched `featured_articles`.
struct FaqCategory: Decodable {
    let id: UUID
    let title: String
    let iconUrl: String?
    let displayOrder: Int
    let featuredArticles: [FaqArticlePreview]
}
