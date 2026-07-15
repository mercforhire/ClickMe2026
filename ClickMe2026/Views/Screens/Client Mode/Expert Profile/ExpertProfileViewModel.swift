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
        expert: PublicExpertProfile = .sarahChen,
        glowPulse: Bool = false,
        isFavorited: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.expert = expert
        self.glowPulse = glowPulse
        self.isFavorited = isFavorited
        self.api = api
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
