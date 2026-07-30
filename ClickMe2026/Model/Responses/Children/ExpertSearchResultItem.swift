//
//  ExpertSearchResultItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single expert card from the `search_experts` RPC. Field names mirror
/// what the server actually returns (verified against `/experts/search`):
/// `headline`, `avg_rating`, `total_reviews`, `experience_years`, and
/// `relevance_score`. `totalCount` is a window-function column (same value on
/// every row) used to derive pagination totals.
struct ExpertSearchResultItem: Decodable {
    let expertId: UUID
    let fullName: String?
    let headline: String?
    let avatarUrl: String?
    let experienceYears: Int?
    let avgRating: Double?
    let totalReviews: Int?
    let relevanceScore: Double?
    let expertiseTags: [String]?
    let isFavorite: Bool?
    let totalCount: Int?
}
