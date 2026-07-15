//
//  FaqArticlePreview.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Lightweight FAQ article preview (no full content).
struct FaqArticlePreview: Decodable {
    let id: UUID
    let categoryId: UUID
    let question: String
    let snippet: String?
    let viewCount: Int
}
