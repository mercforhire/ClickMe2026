//
//  FavoriteExpertItem.swift
//  ClickMe2026
//

import Foundation

/// A single row from `GET /client/favorites.experts[]`. Matches the shape
/// documented by the backend: same expert fields as `/client/home` +
/// `/experts/search` plus an `is_favorite` flag (always `true` in this list)
/// and a `favorited_at` timestamp.
///
/// `hourlyRateAmount` is in minor units (cents). Pair with
/// `hourlyRateCurrency` (ISO-4217) for display.
struct FavoriteExpertItem: Decodable, Hashable {
    let expertId: UUID
    let fullName: String?
    let headline: String?
    let avatarUrl: String?
    let experienceYears: Int?
    let avgRating: Double?
    let totalReviews: Int?
    let hourlyRateAmount: Int?
    let hourlyRateCurrency: String?
    let expertiseTags: [String]?
    let isFavorite: Bool
    let favoritedAt: Date?
}
