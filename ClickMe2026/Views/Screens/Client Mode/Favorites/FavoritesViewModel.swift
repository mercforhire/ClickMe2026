//
//  FavoritesViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-25.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class FavoritesViewModel: ObservableObject {

    /// Rows per `GET /client/favorites` page (D-07). The server clamps to 1-100.
    static let pageSize = 20

    // MARK: View state

    /// Loaded favorites plus the paging bookkeeping (D-07). Keyed by expert id.
    @Published private(set) var list = PagedList<FavoriteExpert, UUID>(key: \.pagingKey)
    @Published var glowPulse: Bool
    @Published var state: LoadState = .idle

    /// Surfaced as an alert when a `DELETE /client/favorites/:id` fails and
    /// the visual state rolls back.
    @Published var apiError: String?

    var favorites: [FavoriteExpert] { list.items }
    var isLoadingMore: Bool { list.isLoadingMore }
    /// True when a page after the first failed; the loaded rows stay on screen.
    var hasPageError: Bool { list.pageError != nil }

    // MARK: Dependencies
    private let api: ClickMeAPI

    /// Bumped whenever the list restarts at page 1, so a next-page response
    /// that was in flight at the time is dropped instead of appended to the
    /// wrong list.
    private var generation = 0

    // MARK: Inits

    /// Runtime init — starts empty; call `load()` on view appear to populate
    /// from the server.
    init(api: ClickMeAPI = .shared) {
        self.api = api
        self.glowPulse = false
    }

    /// Preview / test seam — installs canned favorites as if a load had
    /// already succeeded.
    init(
        favorites: [FavoriteExpert],
        glowPulse: Bool = false
    ) {
        self.api = .shared
        self.glowPulse = glowPulse
        self.list.replace(withFirstPage: favorites, hasMore: false)
        self.state = .loaded
    }

    // MARK: - Load

    /// Fetches page 1 of `GET /client/favorites` and populates the list. Skips
    /// re-fetching when already `.loaded`.
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    /// Retry handler for the first-page error view.
    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        state = .loading
        generation += 1
        do {
            let response = try await api.getClientFavorites(page: 1, limit: Self.pageSize)
            list.replace(
                withFirstPage: response.data.experts.map(Self.map),
                hasMore: response.data.pagination?.hasMoreOrDerived ?? false
            )
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
    /// ends the list quietly (the `ClientTransactionsViewModel` rule). Any other
    /// failure keeps every loaded row and sets the list's `pageError`.
    func loadNextPageIfNeeded(currentItem: FavoriteExpert) async {
        guard case .loaded = state else { return }
        guard let index = list.items.firstIndex(where: { $0.pagingKey == currentItem.pagingKey }),
              list.shouldLoadMore(afterItemAt: index)
        else { return }
        await fetchNextPage()
    }

    private func fetchNextPage() async {
        guard list.hasMore, !list.isLoadingMore else { return }

        let requestedGeneration = generation
        let requestedPage = list.nextPage
        list.isLoadingMore = true
        list.pageError = nil
        defer {
            if requestedGeneration == generation { list.isLoadingMore = false }
        }

        do {
            let response = try await api.getClientFavorites(page: requestedPage, limit: Self.pageSize)
            guard requestedGeneration == generation else { return }
            list.append(
                page: response.data.experts.map(Self.map),
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

    // MARK: - Actions

    /// Removes the favorite optimistically (drops from the list with a
    /// spring animation) and calls `DELETE /client/favorites/:id`. Rolls
    /// the row back on failure.
    ///
    /// - Returns: The server round trip, so a test can await it. The view
    ///   ignores it.
    @discardableResult
    func removeFavorite(_ expert: FavoriteExpert) -> Task<Void, Never> {
        guard let expertId = expert.expertId else {
            // Preview / sample rows with no server id — behave locally only.
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                list.remove(key: expert.pagingKey)
            }
            return Task {}
        }

        let removed = withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            list.remove(key: expert.pagingKey)
        }

        return Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.api.removeFavorite(expertId: expertId)
            } catch {
                // Roll the row back into the position it came from.
                if let removed {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        self.list.insert(removed.item, at: removed.index)
                    }
                }
                self.apiError = error.userMessage
            }
        }
    }

    // MARK: - Mapping helpers

    private static func map(_ item: FavoriteExpertItem) -> FavoriteExpert {
        FavoriteExpert(
            expertId: item.expertId,
            name: item.fullName ?? "Expert",
            title: item.headline ?? "",
            tags: item.expertiseTags ?? [],
            // `/client/favorites` doesn't return a bio field per row; we
            // leave the card's bio empty. Card already renders empty bios
            // as an omitted line.
            bio: "",
            imageURL: item.avatarUrl ?? "",
            isFavorited: item.isFavorite
        )
    }
}
