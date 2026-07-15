//
//  FaqRelatedArticle.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A related FAQ article (preview only — no content_markdown or view_count).
struct FaqRelatedArticle: Decodable {
    let id: UUID
    let question: String
    let snippet: String?
}
