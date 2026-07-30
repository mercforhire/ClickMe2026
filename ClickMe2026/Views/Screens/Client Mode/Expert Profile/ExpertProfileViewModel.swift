//
//  ExpertProfileViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExpertProfileViewModel: ObservableObject {

    // MARK: View state
    @Published var glowPulse: Bool
    @Published var isFavorited: Bool
    @Published var isFavoriteInFlight: Bool = false
    /// True once `/experts/:id/reviews` has come back with a summary
    /// (`overall_rating` / `total_reviews`). Before this, `expert.rating`
    /// and `expert.reviewCount` are just whatever the list-row seeded —
    /// often `0` — and the hero renders em-dash placeholders instead
    /// of a misleading "0.0 (0 reviews)".
    @Published var isSummaryLoaded: Bool = false

    /// Surfaced to the view for an alert when a favorite/unfavorite call
    /// fails. Cleared when the alert dismisses.
    @Published var apiError: String?

    // MARK: Data
    @Published var expert: PublicExpertProfile

    // MARK: Dependencies
    private let api: ClickMeAPI

    init(
        expert: PublicExpertProfile = .placeholder,
        glowPulse: Bool = false,
        isFavorited: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.expert = expert
        self.glowPulse = glowPulse
        self.isFavorited = isFavorited
        self.api = api
    }

    // MARK: - Load

    /// Refreshes the profile from `GET /experts/:expertId/details` AND
    /// fetches the first page of `GET /experts/:expertId/reviews` so the
    /// Recent Reviews card renders 3 rows inline (not just a "See all"
    /// link).
    ///
    /// Both calls fire in parallel. No-ops when `expert.expertId` is nil
    /// (hardcoded sample profile). Either call failing is silent — the
    /// pre-seeded profile stays visible.
    ///
    /// The details endpoint returns bio, stats, and topics of discussion,
    /// but not rating / reviewCount / expertiseTags / avatarUrl / isOnline
    /// — those fields are preserved from whatever the caller seeded (e.g.,
    /// `/client/home` recommended-expert data).
    func loadProfileDetails() async {
        guard let expertId = expert.expertId else { return }
        // Sequential rather than `async let` — `async let` bodies run in
        // a nonisolated context, which Swift 6 concurrency rejects for
        // our `@MainActor`-scoped Decodable conformances.
        let details = try? await api.getExpertDetails(id: expertId)
        let reviews = try? await api.getExpertReviews(id: expertId, page: 1, limit: 3)
        // `/experts/:id/details` doesn't include `is_favorite`, so the
        // heart would show empty even on already-favorited experts. Scan
        // the caller's favorites list to reconcile. Cheap for typical
        // accounts; won't cover >100 favorites without pagination — see
        // the follow-up in the summary.
        let favorites = try? await api.getClientFavorites(page: 1, limit: 100)

        var next = expert
        if let details {
            next = Self.merge(details.data, into: next)
        }
        if let reviews {
            next = Self.apply(
                reviews: reviews.data.reviews,
                summary: reviews.data.summary,
                to: next
            )
            isSummaryLoaded = true
        }
        expert = next

        if let favorites,
           favorites.data.experts.contains(where: { $0.expertId == expertId }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                isFavorited = true
            }
        }
    }

    /// Overlays the fields the details endpoint owns (name, title, bio,
    /// stats, topics) onto the existing profile, preserving fields the
    /// endpoint doesn't return.
    private static func merge(
        _ details: PublicProfileDetailsData,
        into existing: PublicExpertProfile
    ) -> PublicExpertProfile {
        let stats = details.profile.stats
        let yearsExp = stats.experienceYears.map { "\($0) Yrs" } ?? existing.yearsExp
        let bookings = "\(stats.totalBookings)"

        return PublicExpertProfile(
            expertId: existing.expertId,
            name: details.profile.name,
            title: details.profile.title ?? existing.title,
            rating: existing.rating,
            reviewCount: existing.reviewCount,
            yearsExp: yearsExp,
            bookings: bookings,
            isOnline: existing.isOnline,
            bio: details.profile.bio ?? existing.bio,
            expertiseTags: existing.expertiseTags,
            topics: details.topicsOfDiscussion.map(Self.mapTopic),
            reviews: existing.reviews,
            imageURL: existing.imageURL
        )
    }

    /// Overlays the server-fetched review list AND aggregate summary
    /// (`overall_rating` / `total_reviews`) onto the existing profile.
    /// The summary is the source of truth for the header stars — the
    /// details endpoint (`/experts/:id/details`) doesn't return it, so
    /// without this pass the header would stay stuck at whatever the
    /// list-row seed provided (often `0.0 / 0 reviews`).
    private static func apply(
        reviews: [ReviewItem],
        summary: ReviewSummary,
        to existing: PublicExpertProfile
    ) -> PublicExpertProfile {
        let mapped: [PublicReview] = reviews.map { item in
            PublicReview(
                reviewer: item.reviewer.name ?? "Anonymous",
                stars: item.rating,
                body: item.comment ?? ""
            )
        }
        return PublicExpertProfile(
            expertId: existing.expertId,
            name: existing.name,
            title: existing.title,
            rating: summary.overallRating ?? existing.rating,
            reviewCount: summary.totalReviews,
            yearsExp: existing.yearsExp,
            bookings: existing.bookings,
            isOnline: existing.isOnline,
            bio: existing.bio,
            expertiseTags: existing.expertiseTags,
            topics: existing.topics,
            reviews: mapped,
            imageURL: existing.imageURL
        )
    }

    /// Converts a server-side topic into the display type. Amounts arrive
    /// in minor units (cents) and represent a **flat per-session price** —
    /// the actual charge the client pays for one booking of this topic.
    /// The server field is named `hourly_rate` on `/client/home` (and
    /// `price` on `/experts/:id/details`); both are misnamed on the wire
    /// but carry the same per-session amount. Duration is shown
    /// separately by the row.
    private static func mapTopic(_ t: PublicProfileDetailsData.TopicOfDiscussion) -> PublicTopic {
        let duration = t.durationMins.map { "\($0) mins" } ?? ""
        let priceString: String
        if t.price.isFree {
            priceString = "Free"
        } else if let amount = t.price.amount, let currency = t.price.currency {
            priceString = Self.formatSessionPrice(amount: amount, currency: currency)
        } else {
            priceString = "—"
        }
        return PublicTopic(
            title: t.title,
            duration: duration,
            description: t.description ?? "",
            price: priceString,
            isFree: t.price.isFree
        )
    }

    /// `$50` for a 5000-cent CAD topic — per-session flat price, currency
    /// formatted via `NumberFormatter`. Amount is minor units; currency is
    /// ISO-4217.
    private static func formatSessionPrice(amount: Int, currency: String) -> String {
        let amountMajor = Double(amount) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = amountMajor.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amountMajor))
            ?? "\(currency) \(String(format: "%.0f", amountMajor))"
    }

    // MARK: Actions

    /// Optimistically flips the heart, then hits `PUT` / `DELETE
    /// /client/favorites/:expertId`. On failure, rolls the visual state
    /// back and surfaces the server message via `apiError`.
    ///
    /// No-op if `expert.expertId` is nil (e.g., a hardcoded sample profile
    /// with no server backing).
    func toggleFavorite() async {
        guard let expertId = expert.expertId else { return }
        guard !isFavoriteInFlight else { return }

        let previous = isFavorited

        // Optimistic flip.
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            isFavorited.toggle()
        }
        isFavoriteInFlight = true
        defer { isFavoriteInFlight = false }

        do {
            let response: SuccessDataResponse<ToggleFavoriteData>
            if previous {
                response = try await api.removeFavorite(expertId: expertId)
            } else {
                response = try await api.addFavorite(expertId: expertId)
            }
            // Reconcile against the server's authoritative view. Idempotent
            // endpoints mean the server may report the same state we picked;
            // this handles the rare drift case (e.g., another device toggled).
            isFavorited = response.data.isFavorite
        } catch {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                isFavorited = previous
            }
            apiError = Self.message(for: error)
        }
    }

    // MARK: - Error helpers

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
