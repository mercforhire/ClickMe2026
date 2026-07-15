//
//  DiscoveryFeedSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single feed section from the `discovery_feed` RPC. Shape is RPC-owned and may
/// evolve independently of this spec.
struct DiscoveryFeedSection: Decodable {
    struct Expert: Decodable {
        let expertId: UUID
        let fullName: String?
        let avatarUrl: String?
        let bioSnippet: String?
        let hourlyRateAmount: Int?
        let hourlyRateCurrency: String?
        let isFavorite: Bool?
    }

    let sectionType: String
    let sectionTitle: String?
    let layout: String?
    let experts: [Expert]?
}
