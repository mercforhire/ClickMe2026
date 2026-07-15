//
//  PublicProfileDetailsData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Simplified expert card details. Stubs (D-11): `total_bookings=0`,
/// `avg_response_time=null`, `recent_reviews=[]`.
struct PublicProfileDetailsData: Decodable {
    struct Profile: Decodable {
        struct Stats: Decodable {
            let experienceYears: Int?
            let totalBookings: Int
            let avgResponseTime: String?
        }

        let name: String
        let title: String?
        let bio: String?
        let stats: Stats
    }

    struct TopicOfDiscussion: Decodable {
        struct Price: Decodable {
            let amount: Int?
            let currency: String?
            let isFree: Bool
        }

        let id: UUID
        let title: String
        let durationMins: Int?
        let description: String?
        let price: Price
    }

    let profile: Profile
    let topicsOfDiscussion: [TopicOfDiscussion]
    let recentReviews: [JSONValue]
}
