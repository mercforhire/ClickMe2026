//
//  FaqArticle.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Full FAQ article with content_markdown and related articles.
/// Response key `title` is mapped server-side from the live DB column `question`.
struct FaqArticle: Decodable {
    let id: UUID
    let title: String
    let contentMarkdown: String
    let lastUpdated: Date
    let relatedArticles: [FaqRelatedArticle]
}
