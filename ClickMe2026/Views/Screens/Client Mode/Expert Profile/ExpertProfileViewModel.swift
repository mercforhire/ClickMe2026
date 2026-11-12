//
//  ExpertProfileViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Where the profile screen is in loading `GET /experts/:id/details`.
///
/// `loading` is the initial state and keeps the seeded profile on screen with
/// no spinner. `notFound` and `failed` replace the whole profile with a state
/// view, so a seeded profile is never presented as if it had loaded (D-10).
enum ExpertProfileLoadState: Equatable {
    case loading
    case loaded
    /// The server answered 404: a deleted, suspended or non-expert account.
    /// It will not change on its own, so there is no Retry.
    case notFound
    /// Any other failure (transport, 5xx, decoding), with the text to show.
    case failed(String)
}

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

    /// Decided only by the details call; see `loadProfileDetails()`.
    @Published private(set) var loadState: ExpertProfileLoadState = .loading

    /// True while a Retry tap is running. The state view swaps its capsule
    /// for a spinner and further taps are ignored.
    @Published private(set) var isRetrying: Bool = false

    // MARK: Data
    @Published var expert: PublicExpertProfile

    // MARK: Dependencies
    private let api: ClickMeAPI

    /// Lets only the most recently started load write the profile, the heart
    /// or the load state, so a `.task` rerun or a Retry cannot be overwritten
    /// by an older response that lands later.
    private var loadGate = ReloadGeneration()

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

    /// Loads the profile from `GET /experts/:expertId/details`, then fetches
    /// the first page of `GET /experts/:expertId/reviews` so the Recent
    /// Reviews card renders 3 rows inline (not just a "See all" link).
    ///
    /// The details call alone decides `loadState` (D-10). A 404 (status or
    /// `ErrorCode.notFound`, never message text) means `.notFound`; any other
    /// thrown error means `.failed` with `Error.userMessage`. While it runs
    /// the seeded profile shows as before, with no spinner. The reviews call
    /// runs only after details succeeded and stays best-effort and silent.
    ///
    /// Only the newest started load writes anything (`loadGate`); a
    /// cancelled load (the view went away) writes nothing. No-ops to
    /// `.loaded` when `expert.expertId` is nil (hardcoded sample profile).
    ///
    /// The details endpoint returns bio, stats, and topics of discussion,
    /// but not rating / reviewCount / expertiseTags / avatarUrl / isOnline
    /// — those fields are preserved from whatever the caller seeded (e.g.,
    /// `/client/home` recommended-expert data).
    func loadProfileDetails() async {
        guard let expertId = expert.expertId else {
            loadState = .loaded
            return
        }
        let token = loadGate.begin()

        // Sequential rather than `async let` — `async let` bodies run in
        // a nonisolated context, which Swift 6 concurrency rejects for
        // our `@MainActor`-scoped Decodable conformances.
        let details: SuccessDataResponse<PublicProfileDetailsData>
        do {
            details = try await api.getExpertDetails(id: expertId)
        } catch {
            guard loadGate.isCurrent(token), !Self.isCancellation(error) else { return }
            loadState = Self.isNotFound(error) ? .notFound : .failed(error.userMessage)
            return
        }
        guard loadGate.isCurrent(token) else { return }
        expert = Self.merge(details.data, into: expert)
        loadState = .loaded

        // `/experts/:id/details` doesn't include `is_favorite` yet, so the
        // heart would show empty even on already-favorited experts. Scan
        // the caller's favorites list to reconcile.
        let favorites = try? await api.getClientFavorites(page: 1, limit: 100)
        let reviews = try? await api.getExpertReviews(id: expertId, page: 1, limit: 3)
        guard loadGate.isCurrent(token) else { return }

        if let reviews {
            expert = Self.apply(
                reviews: reviews.data.reviews,
                summary: reviews.data.summary,
                to: expert
            )
            isSummaryLoaded = true
        }
        if let favorites,
           favorites.data.experts.contains(where: { $0.expertId == expertId }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                isFavorited = true
            }
        }
    }

    /// Re-runs the details load from the load-failed state. A tap while a
    /// retry is already running is ignored, so quick double taps issue one
    /// request.
    func retry() async {
        guard !isRetrying else { return }
        isRetrying = true
        defer { isRetrying = false }
        await loadProfileDetails()
    }

    /// True for a 404, by status code or by the body's `ErrorCode`.
    private static func isNotFound(_ error: Error) -> Bool {
        if case let NetworkError.httpError(statusCode, _) = error, statusCode == 404 {
            return true
        }
        return BookingErrorMapper.code(for: error) == .notFound
    }

    private static func isCancellation(_ error: Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
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
            imageURL: existing.imageURL,
            // Backend flag — nil (not shipped yet) defaults to bookable.
            isBookable: details.isBookable ?? existing.isBookable
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
            imageURL: existing.imageURL,
            isBookable: existing.isBookable
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

    /// `$50.00` for a 5000-cent USD topic (`CA$50.00` for CAD) — per-session
    /// flat price, formatted by `Money`. Amount is minor units; currency is
    /// ISO-4217.
    private static func formatSessionPrice(amount: Int, currency: String) -> String {
        Money.format(minorUnits: amount, currency: currency)
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
