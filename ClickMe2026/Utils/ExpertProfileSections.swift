//
//  ExpertProfileSections.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-12.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which sections of an expert's public profile are drawn, and what the hero
/// rating row says (EXPL-02, 04-UI-SPEC EM2 and Z1).
///
/// Before this, the Expertise, Topics and Recent Reviews sections drew their
/// headers and padding for empty input, and a zero-review expert read
/// "0.0 (0 reviews)". A profile opened from a chat is seeded with no
/// expertise tags and the details response carries tags per topic only, so
/// its Expertise header was always bare.
enum ExpertProfileSections {

    // MARK: Section visibility

    /// Hidden with no tags. A chat-opened profile always has none (the
    /// details response carries tags per topic, not per profile), so its
    /// Expertise section is hidden rather than derived; deriving it from the
    /// topics' tags is a logged follow-up (RESEARCH Open Question 5).
    static func showsExpertise(_ tags: [PublicExpertTag]) -> Bool {
        !tags.isEmpty
    }

    static func showsTopics(_ topics: [PublicTopic]) -> Bool {
        !topics.isEmpty
    }

    static func showsReviews(_ reviews: [PublicReview]) -> Bool {
        !reviews.isEmpty
    }

    // MARK: Hero rating row

    /// What the hero rating row draws: an optional star, an optional bold
    /// value and a caption label.
    struct Rating: Equatable {
        let showsStar: Bool
        let value: String?
        let label: String
    }

    /// - Parameters:
    ///   - summaryLoaded: False until the reviews summary lands, so a first
    ///     visit shows placeholders instead of a misleading "0.0 (0 reviews)".
    ///   - rating: The average rating; drawn with one decimal.
    ///   - reviewCount: Zero reads "No reviews yet" with no star and no value.
    static func rating(summaryLoaded: Bool, rating: Double, reviewCount: Int) -> Rating {
        guard summaryLoaded else {
            return Rating(showsStar: true, value: "—", label: "(— reviews)")
        }
        guard reviewCount > 0 else {
            return Rating(showsStar: false, value: nil, label: "No reviews yet")
        }
        let label = reviewCount == 1 ? "(1 review)" : "(\(reviewCount) reviews)"
        return Rating(showsStar: true, value: String(format: "%.1f", rating), label: label)
    }
}
