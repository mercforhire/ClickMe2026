//
//  ReviewContextData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Review eligibility context for a booking. `hasSubmitted = true` means the caller
/// has already submitted a review (and `prefill` carries their prior values).
struct ReviewContextData: Decodable {
    struct ReviewTarget: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
        let role: String?
    }

    struct Prefill: Decodable {
        let rating: Int
        let comment: String?
        let tags: [String]?
    }

    let hasSubmitted: Bool
    let reviewTarget: ReviewTarget
    let sessionTopic: String?
    let prefill: Prefill?
}
