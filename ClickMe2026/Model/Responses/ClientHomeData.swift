//
//  ClientHomeData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Home feed payload from the `home_feed` RPC. Shape is RPC-owned.
struct ClientHomeData: Decodable {
    struct TrendingCategory: Decodable {
        /// Stable text slug (e.g. "technology", "real-estate") matching the
        /// `/categories` reference vocab — NOT a UUID.
        let id: String
        let name: String?
        let iconName: String?
        let colorAccent: String?
    }

    struct RecommendedExpert: Decodable {
        struct BaseHourlyRate: Decodable {
            let amount: Double?
            let currency: String?
        }

        let expertId: UUID
        let fullName: String?
        let title: String?
        let profileImageUrl: String?
        let rating: Double?
        let reviewCount: Int?
        let yearsExperience: Int?
        let expertiseTags: [String]?
        let baseHourlyRate: BaseHourlyRate?
        let isFavorite: Bool
    }

    let trendingCategories: [TrendingCategory]
    let recommendedExperts: [RecommendedExpert]
}
