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

    /// Refreshes the profile from `GET /experts/:expertId/details`. No-ops
    /// when `expert.expertId` is nil (e.g., a hardcoded sample profile) or
    /// when the call fails — in the failure case the existing profile is
    /// left in place so the UI never blanks out.
    ///
    /// The details endpoint returns bio, stats, and topics of discussion,
    /// but not rating / reviewCount / expertiseTags / avatarUrl / isOnline
    /// — those fields are preserved from whatever the caller seeded (e.g.,
    /// `/client/home` recommended-expert data).
    func loadProfileDetails() async {
        guard let expertId = expert.expertId else { return }
        do {
            let response = try await api.getExpertDetails(id: expertId)
            expert = Self.merge(response.data, into: expert)
        } catch {
            // Silent — the pre-seeded profile stays visible.
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

    /// Converts a server-side topic into the display type. Amounts arrive
    /// in minor units (cents), so divide by 100 for display. Currency code
    /// is passed through — future formatter can map ISO-4217 to a symbol.
    private static func mapTopic(_ t: PublicProfileDetailsData.TopicOfDiscussion) -> PublicTopic {
        let duration = t.durationMins.map { "\($0) mins" } ?? ""
        let priceString: String
        if t.price.isFree {
            priceString = "Free"
        } else if let amount = t.price.amount, let currency = t.price.currency {
            priceString = "\(currency) \(amount / 100)"
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
