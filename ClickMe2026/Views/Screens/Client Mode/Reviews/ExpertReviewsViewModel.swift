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

    /// Reviews per `GET /experts/:id/reviews` page (D-07). The server default is
    /// 10, so the limit is always sent.
    static let pageSize = 20

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
    /// Loaded reviews plus the paging bookkeeping (D-07). Keyed by server review id.
    @Published private(set) var list = PagedList<ExpertReview, UUID>(key: \.pagingKey)
    @Published var state: LoadState

    var reviews: [ExpertReview] { list.items }
    var isLoadingMore: Bool { list.isLoadingMore }
    /// True when a page after the first failed; the loaded reviews stay on screen.
    var hasPageError: Bool { list.pageError != nil }

    // MARK: Dependencies
    private let api: ClickMeAPI

    /// Bumped whenever the list restarts at page 1, so a next-page response
    /// that was in flight at the time is dropped instead of appended to the
    /// wrong list.
    private var generation = 0

    /// True while a page-1 restart is running, so a second trigger or a second
    /// pull cannot start another one.
    private var isRefreshing = false

    // MARK: Inits

    /// Runtime init — starts empty; `load()` on view appear populates from
    /// `GET /experts/:id/reviews`.
    init(expertId: UUID?, expertName: String = "", api: ClickMeAPI = .shared) {
        self.expertId = expertId
        self.expertName = expertName
        self.api = api
        self.overallRating = 0
        self.totalReviews = 0
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
        self.state = .loaded
        self.list.replace(withFirstPage: reviews, hasMore: false)
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

    /// Retry handler for the first-page error view.
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
        generation += 1
        do {
            let response = try await api.getExpertReviews(id: expertId, page: 1, limit: Self.pageSize)
            install(firstPage: response.data)
            state = .loaded
        } catch {
            state = .failed(error.userMessage)
        }
    }

    // MARK: - Paging

    /// Fires from each row's `.onAppear`. Fetches the next page when the row
    /// is one of the last 3 loaded and no page is loading; stops when the
    /// server reports `has_more` false.
    ///
    /// A 500 on a page after the first is PostgREST's out-of-range answer and
    /// ends the list quietly. Any other failure keeps every loaded review and
    /// sets the list's `pageError`; the footer's Retry is then the only way
    /// forward, so scrolling back over the last rows does not fire the request
    /// again by itself.
    func loadNextPageIfNeeded(currentItem: ExpertReview) async {
        guard case .loaded = state, !isRefreshing, list.pageError == nil else { return }
        guard let index = list.items.firstIndex(where: { $0.pagingKey == currentItem.pagingKey }),
              list.shouldLoadMore(afterItemAt: index)
        else { return }
        await fetchNextPage()
    }

    /// The footer's Retry after a failed later page. Runs the fetch without the
    /// row-index check.
    func retryNextPage() async {
        guard case .loaded = state, !isRefreshing else { return }
        list.pageError = nil
        await fetchNextPage()
    }

    /// Pull-to-refresh. Restarts at page 1 without touching `state`, so the
    /// reviews stay on screen. A success replaces the list; a failure keeps it
    /// and shows nothing new (public read-only data).
    func refresh() async {
        guard let expertId, case .loaded = state, !isRefreshing else { return }
        isRefreshing = true
        generation += 1
        // A next-page fetch still in flight is now stale: its result is dropped
        // and its `defer` no longer clears the marker, so clear it here.
        list.isLoadingMore = false
        let requestedGeneration = generation
        defer { isRefreshing = false }

        do {
            let response = try await api.getExpertReviews(id: expertId, page: 1, limit: Self.pageSize)
            guard requestedGeneration == generation else { return }
            install(firstPage: response.data)
        } catch {
            // Keep the rows on screen; the refresh control simply ends.
        }
    }

    private func fetchNextPage() async {
        guard let expertId, list.hasMore, !list.isLoadingMore else { return }

        let requestedGeneration = generation
        let requestedPage = list.nextPage
        list.isLoadingMore = true
        list.pageError = nil
        defer {
            if requestedGeneration == generation { list.isLoadingMore = false }
        }

        do {
            let response = try await api.getExpertReviews(id: expertId, page: requestedPage, limit: Self.pageSize)
            guard requestedGeneration == generation else { return }
            list.append(
                page: response.data.reviews.map(Self.map),
                hasMore: response.data.pagination?.hasMoreOrDerived ?? false
            )
        } catch {
            guard requestedGeneration == generation else { return }
            if requestedPage > 1,
               case let NetworkError.httpError(status, _) = error,
               status == 500 {
                list.markEnd()
                return
            }
            list.pageError = error.userMessage
        }
    }

    /// Installs page 1 and the header numbers. The count and rating come from
    /// `summary`; the pagination envelope has no total (RESEARCH Pitfall 3).
    private func install(firstPage payload: ExpertReviewsPayload) {
        overallRating = payload.summary.overallRating ?? 0
        totalReviews = payload.summary.totalReviews
        list.replace(
            withFirstPage: payload.reviews.map(Self.map),
            hasMore: payload.pagination?.hasMoreOrDerived ?? false
        )
    }

    // MARK: - Mapping helpers

    private static func map(_ item: ReviewItem) -> ExpertReview {
        ExpertReview(
            reviewerName: item.reviewer.name ?? "Anonymous",
            reviewerImageURL: item.reviewer.avatarUrl ?? "",
            topic: item.sessionContext.topic ?? "",
            stars: Double(item.rating),
            dateLabel: item.sessionContext.dateLabel,
            body: item.comment ?? "",
            serverId: item.id
        )
    }
}
