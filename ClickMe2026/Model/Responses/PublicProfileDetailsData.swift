//
//  PublicProfileDetailsData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Simplified expert card details. Stubs (D-11): `total_bookings=0`,
/// `recent_reviews=[]`.
struct PublicProfileDetailsData: Decodable {
    struct Profile: Decodable {
        struct Stats: Decodable {
            let experienceYears: Int?
            let totalBookings: Int
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

    /// Whether this expert can accept new bookings right now. Mirrors
    /// the caller-scoped `charges_enabled` from
    /// `/expert/connect/status` but for arbitrary experts so client
    /// mode can hide the Book button before the user taps and hits a
    /// 422 `EXPERT_NOT_BOOKABLE`.
    ///
    /// Optional — backend hasn't shipped the field yet. Nil defaults
    /// to `true` (show the button) in `isBookable`, so we don't hide
    /// the CTA for existing experts before the field lands.
    let isBookable: Bool?
}
