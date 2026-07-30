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
        let expertId: UUID
        let fullName: String?
        let title: String?
        let profileImageUrl: String?
        let rating: Double?
        let reviewCount: Int?
        let yearsExperience: Int?
        let expertiseTags: [String]?
        let isFavorite: Bool
    }

    /// Curated "Featured Topics" strip shown on the client Explore
    /// screen. Server-picked from published topics (random per request,
    /// deduped by expert). Optional so the client can decode responses
    /// from older server versions before the field is deployed — an
    /// absent or empty array hides the section on the UI.
    struct FeaturedTopic: Decodable {
        struct HourlyRate: Decodable {
            /// Minor units (e.g. cents).
            let amount: Int
            /// ISO 4217, uppercase — e.g. "USD".
            let currency: String
        }

        struct Expert: Decodable {
            let expertId: UUID
            let fullName: String?
            let profileImageUrl: String?
        }

        let topicId: UUID
        let title: String
        /// Optional — some topics don't have a fixed duration.
        let durationMins: Int?
        let hourlyRate: HourlyRate?
        let expert: Expert
    }

    let trendingCategories: [TrendingCategory]
    let recommendedExperts: [RecommendedExpert]
    /// Nil / empty until the backend deploys the field or when there
    /// are no eligible topics on the account.
    let featuredTopics: [FeaturedTopic]?
}
