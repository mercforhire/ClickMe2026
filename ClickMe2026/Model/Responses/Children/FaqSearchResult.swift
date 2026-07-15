//
//  FaqSearchResult.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single FAQ search result from the `search_faqs` RPC. Each row carries a
/// `total_count` window function column used for pagination.
struct FaqSearchResult: Decodable {
    let id: UUID
    let categoryId: UUID?
    let question: String?
    let snippet: String?
    let viewCount: Int?
    let totalCount: Int?
}
