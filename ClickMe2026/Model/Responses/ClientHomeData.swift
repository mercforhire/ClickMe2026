//
//  ClientHomeData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
            /// Minor units (e.g. cents). Optional because production sends
            /// `{amount: 0, currency: null}` for free topics created with no price.
            let amount: Int?
            /// ISO 4217, uppercase — e.g. "USD". Null for the same free topics.
            let currency: String?
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
        /// Authoritative free flag. A free topic can arrive with a null or zero
        /// rate, so the label must not be inferred from `hourlyRate` alone.
        let isFree: Bool?
        let expert: Expert
    }

    /// Decodes one featured topic and drops it on failure, so a single
    /// malformed element cannot fail the whole home feed.
    private struct LossyFeaturedTopic: Decodable {
        let value: FeaturedTopic?

        init(from decoder: Decoder) throws {
            do {
                value = try FeaturedTopic(from: decoder)
            } catch {
                #if DEBUG
                print("home_feed: dropped a featured topic: \(error)")
                #endif
                value = nil
            }
        }
    }

    let trendingCategories: [TrendingCategory]
    let recommendedExperts: [RecommendedExpert]
    /// Nil / empty until the backend deploys the field or when there
    /// are no eligible topics on the account.
    let featuredTopics: [FeaturedTopic]?

    private enum CodingKeys: String, CodingKey {
        case trendingCategories, recommendedExperts, featuredTopics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trendingCategories = try container.decode([TrendingCategory].self, forKey: .trendingCategories)
        recommendedExperts = try container.decode([RecommendedExpert].self, forKey: .recommendedExperts)
        featuredTopics = try container.decodeIfPresent([LossyFeaturedTopic].self, forKey: .featuredTopics)?
            .compactMap(\.value)
    }
}
