//
//  BookingTopic.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Client-side display model of an expert's topic of discussion. Backed by
/// the server-side `PublicProfileDetailsData.TopicOfDiscussion` — `id` is
/// the authoritative server UUID, needed when firing booking requests.
struct BookingTopic: Identifiable, Hashable {
    let id: UUID
    let title: String
    let durationMinutes: Int
    /// Price in minor units (cents). `nil` when the topic is free or price
    /// isn't set on the server.
    let priceAmount: Int?
    let currency: String?
    let isFree: Bool

    /// Human-readable price label. "Free", "USD 50", or "—" when unknown.
    var priceLabel: String {
        if isFree { return "Free" }
        if let priceAmount, let currency {
            return "\(currency) \(priceAmount / 100)"
        }
        return "—"
    }

    /// Duration label used in the topic picker + summary.
    var durationLabel: String { "\(durationMinutes) min" }
}
