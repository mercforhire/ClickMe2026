//
//  ReviewSummary.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Aggregate review summary from the `get_expert_review_aggregate` RPC.
struct ReviewSummary: Decodable {
    /// Per-star review counts. JSON keys are `5_star`, `4_star`, … but the
    /// shared `JSONDecoder` runs `.convertFromSnakeCase`, which transforms
    /// those to `5Star`, `4Star`, … BEFORE looking up `CodingKeys`. So the
    /// raw values below must match the *post-conversion* form, not the
    /// original JSON keys.
    struct RatingDistribution: Decodable {
        let fiveStar: Int
        let fourStar: Int
        let threeStar: Int
        let twoStar: Int
        let oneStar: Int

        enum CodingKeys: String, CodingKey {
            case fiveStar  = "5Star"
            case fourStar  = "4Star"
            case threeStar = "3Star"
            case twoStar   = "2Star"
            case oneStar   = "1Star"
        }
    }

    let expertId: UUID
    let overallRating: Double?
    let totalReviews: Int
    let ratingDistribution: RatingDistribution
}
