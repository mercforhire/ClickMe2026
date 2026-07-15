//
//  PublicProfileData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Full public expert profile.
///
/// x-discrepancy #3: `header.is_online`, `header.rating`, `header.total_reviews`,
/// `quick_stats.total_bookings`, `quick_stats.response_time`, and
/// `recent_reviews.items` are currently stub values (D-09/D-11 placeholders).
struct PublicProfileData: Decodable {
    struct Header: Decodable {
        let fullName: String
        let headline: String?
        let profileImageUrl: String?
        let isOnline: Bool
        let rating: Double
        let totalReviews: Int
    }

    struct QuickStats: Decodable {
        let experienceYears: Int?
        let totalBookings: Int
        let responseTime: String?
    }

    struct About: Decodable {
        let bio: String?
    }

    struct Expertise: Decodable {
        let id: UUID
        let label: String
        let isPrimary: Bool?
    }

    struct DiscussionTopic: Decodable {
        struct Price: Decodable {
            let amount: Int?
            let currency: String?
            let label: String?
        }

        let id: UUID
        let title: String
        let metadata: String?
        let price: Price
    }

    struct RecentReviews: Decodable {
        let summaryLink: String
        let items: [JSONValue]
    }

    let profileId: UUID
    let header: Header
    let quickStats: QuickStats
    let about: About
    let expertise: [Expertise]
    let discussionTopics: [DiscussionTopic]
    let recentReviews: RecentReviews
}
