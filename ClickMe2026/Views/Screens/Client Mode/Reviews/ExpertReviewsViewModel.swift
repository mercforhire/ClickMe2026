//
//  ExpertReviewsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExpertReviewsViewModel: ObservableObject {


    // MARK: Identity
    /// Server UUID of the expert whose reviews we're rendering. Nil when
    /// running under the preview seam that installs canned data.
    let expertId: UUID?
    /// Expert's display name, used to personalize the nav-bar title
    /// ("Sophia's Reviews"). Empty when unknown — the view falls back
    /// to a generic "Reviews" label in that case.
    let expertName: String

    // MARK: Content
    @Published var overallRating: Double
    @Published var totalReviews: Int
    @Published var reviews: [ExpertReview]
    @Published var state: LoadState

    // MARK: Dependencies
    private let api: ClickMeAPI

    // MARK: Inits

    /// Runtime init — starts empty; `load()` on view appear populates from
    /// `GET /experts/:id/reviews`.
    init(expertId: UUID?, expertName: String = "", api: ClickMeAPI = .shared) {
        self.expertId = expertId
        self.expertName = expertName
        self.api = api
        self.overallRating = 0
        self.totalReviews = 0
        self.reviews = []
        self.state = .idle
    }

    /// Preview seam — installs canned data as if a load had already
    /// succeeded. Used by the "sample data" preview to render without
    /// hitting the network.
    init(
        expertName: String = "",
        overallRating: Double,
        totalReviews: Int,
        reviews: [ExpertReview]
    ) {
        self.expertId = nil
        self.expertName = expertName
        self.api = .shared
        self.overallRating = overallRating
        self.totalReviews = totalReviews
        self.reviews = reviews
        self.state = .loaded
    }

    // MARK: - Derived

    /// Nav-bar title. Uses the expert's first name only (keeps the bar
    /// readable in `.inline` mode) and falls back to "Reviews" when no
    /// name is available.
    var navigationTitle: String {
        let trimmed = expertName.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.split(separator: " ").first.map(String.init),
              !first.isEmpty else {
            return "Reviews"
        }
        return "\(first)'s Reviews"
    }

    // MARK: - Load

    /// Fetches page 1 of the reviews list. Idempotent — skips if already
    /// loaded (avoids clobbering the preview seam).
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    /// Pull-to-refresh handler.
    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        // No expertId (preview seam) — leave whatever seed is in place.
        guard let expertId else {
            state = .loaded
            return
        }
        state = .loading
        do {
            let response = try await api.getExpertReviews(id: expertId)
            overallRating = response.data.summary.overallRating ?? 0
            totalReviews = response.data.summary.totalReviews
            reviews = response.data.reviews.map(Self.map)
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    // MARK: - Mapping helpers

    private static func map(_ item: ReviewItem) -> ExpertReview {
        ExpertReview(
            reviewerName: item.reviewer.name ?? "Anonymous",
            reviewerImageURL: item.reviewer.avatarUrl ?? "",
            topic: item.sessionContext.topic ?? "",
            stars: Double(item.rating),
            dateLabel: item.sessionContext.dateLabel,
            body: item.comment ?? ""
        )
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
