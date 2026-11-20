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

    /// True while a page-1 restart is running, so a second trigger or a second
    /// pull cannot start another one.
    private var isRefreshing = false

    /// True after the profile pushed from this list toggled the heart, so the
    /// list may no longer match the server. `noteProfileFavoriteChanged()`
    /// revalidates at once; `load()` retries while it is still set (WR-11, WR-13).
    private var needsRevalidation = false

    /// Counts the profile heart changes. A response clears `needsRevalidation` only
    /// when no change happened since its request started: an older response may
    /// predate the toggle and must not wipe the flag (WR-13).
    private var revalidationEpoch = 0

    // MARK: Removal bookkeeping (WR-11)

    /// Experts whose `DELETE` is running. A list response never shows them.
    private var pendingRemovals: Set<UUID> = []

    /// Counts the requests that read the list (page 1, refresh, next page). A
    /// request takes the next number when it starts.
    private var requestSerial = 0

    /// For an expert whose `DELETE` succeeded, the value of `requestSerial` at
    /// that moment. A list request numbered at or below it started before the
    /// `DELETE` ended, so the server may have answered it with the row still in
    /// it. Later requests are not affected, so a re-favorited expert comes back.
    private var removalFinishedAt: [UUID: Int] = [:]

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

    /// Fetches page 1 of `GET /client/favorites` and populates the list. When
    /// already `.loaded` it fetches nothing, unless the profile opened from this
    /// list changed a favorite (`noteProfileFavoriteChanged()`). Then it
    /// revalidates quietly: the rows stay on screen and a failure raises no alert.
    func load() async {
        if case .loaded = state {
            guard needsRevalidation else { return }
            await refresh(quietly: true)
            return
        }
        await forceLoad()
    }

    /// Called when the profile pushed from this list toggled the favorite heart.
    /// The server state changed behind the list, so it revalidates now, quietly:
    /// this view model is owned by the list's `@StateObject` and stays alive while
    /// the profile is pushed or has already been popped. Waiting for the next
    /// `load()` missed a toggle that finished after the user had gone back, because
    /// the `.task` had already run (WR-13). If a refresh is already running, it runs
    /// once more when it ends, so its older response cannot stand for this change.
    /// A failed revalidation leaves the flag set, so the next `load()` tries again.
    ///
    /// - Returns: The revalidation, so a test can await it. The view ignores it.
    @discardableResult
    func noteProfileFavoriteChanged() -> Task<Void, Never> {
        revalidationEpoch += 1
        needsRevalidation = true
        return Task { await refresh(quietly: true) }
    }

    /// Retry handler for the first-page error view.
    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        let previous = state
        state = .loading
        generation += 1
        let serial = beginListRequest()
        let epoch = revalidationEpoch
        do {
            let response = try await api.getClientFavorites(page: 1, limit: Self.pageSize)
            list.replace(
                withFirstPage: rows(from: response.data.experts, requestSerial: serial),
                hasMore: response.data.pagination?.hasMoreOrDerived ?? false
            )
            if revalidationEpoch == epoch { needsRevalidation = false }
            state = .loaded
        } catch {
            // IN-15: a cancelled load (the screen went away) is not a failure; `.task` loads again on appear.
            state = error.isCancellation ? state.afterCancelledLoad(previous: previous) : .failed(error.userMessage)
        }
    }

    // MARK: - Paging

    /// Fires from each row's `.onAppear`. Fetches the next page when the row
    /// is one of the last 3 loaded and no page is loading; stops when the
    /// server reports `has_more` false.
    ///
    /// A 500 on a page after the first is PostgREST's out-of-range answer and
    /// ends the list quietly (the `ClientTransactionsViewModel` rule). Any other
    /// failure keeps every loaded row and sets the list's `pageError`; the
    /// footer's Retry is then the only way forward, so scrolling back over the
    /// last rows does not fire the request again by itself.
    ///
    /// Reload-on-next-trigger (RESEARCH Open Question 4): after an unfavorite
    /// while more pages remain, the server's offsets have moved up by one, so
    /// asking for the next offset would skip the row that moved into the gap.
    /// The first trigger after that restarts at page 1 instead.
    func loadNextPageIfNeeded(currentItem: FavoriteExpert) async {
        guard case .loaded = state, !isRefreshing, list.pageError == nil else { return }
        guard let index = list.items.firstIndex(where: { $0.pagingKey == currentItem.pagingKey }),
              list.shouldLoadMore(afterItemAt: index)
        else { return }

        if list.isStale {
            await refresh()
        } else {
            await fetchNextPage()
        }
    }

    /// The footer's Retry after a failed later page. Runs the fetch without the
    /// row-index check; a stale list restarts at page 1 instead.
    func retryNextPage() async {
        guard case .loaded = state, !isRefreshing else { return }
        list.pageError = nil
        if list.isStale {
            await refresh()
        } else {
            await fetchNextPage()
        }
    }

    /// Pull-to-refresh. Restarts at page 1 without touching `state`, so the
    /// rows stay on screen. A success replaces the list; a failure keeps it and
    /// raises the "Couldn't update favorites" alert through `apiError`.
    ///
    /// - Parameter quietly: True for the revalidation after the profile changed a
    ///   favorite (WR-11). A failure then keeps the list and raises no alert,
    ///   and the next `load()` tries again.
    func refresh(quietly: Bool = false) async {
        guard case .loaded = state, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        var quiet = quietly
        while true {
            let epoch = revalidationEpoch
            await restartAtFirstPage(quietly: quiet, epoch: epoch)
            // The profile changed a favorite while this request ran (WR-13): its response may
            // predate the change, so ask again. A later change repeats this; a failure does not.
            guard revalidationEpoch != epoch, !Task.isCancelled, case .loaded = state else { return }
            quiet = true
        }
    }

    /// One page-1 request for `refresh(quietly:)`. Clears `needsRevalidation` only when no heart
    /// change happened since it started (`epoch`).
    private func restartAtFirstPage(quietly: Bool, epoch: Int) async {
        generation += 1
        // A next-page fetch still in flight is now stale: its result is dropped
        // and its `defer` no longer clears the marker, so clear it here.
        list.isLoadingMore = false
        let requestedGeneration = generation
        let serial = beginListRequest()

        do {
            let response = try await api.getClientFavorites(page: 1, limit: Self.pageSize)
            guard requestedGeneration == generation else { return }
            list.replace(
                withFirstPage: rows(from: response.data.experts, requestSerial: serial),
                hasMore: response.data.pagination?.hasMoreOrDerived ?? false
            )
            if revalidationEpoch == epoch { needsRevalidation = false }
        } catch {
            // The pull gesture's task is cancelled when the view goes away;
            // that is not a failed refresh.
            if error.isCancellation { return }
            if !quietly { apiError = error.userMessage }
        }
    }

    private func fetchNextPage() async {
        guard list.hasMore, !list.isLoadingMore else { return }

        let requestedGeneration = generation
        let requestedPage = list.nextPage
        let serial = beginListRequest()
        list.isLoadingMore = true
        list.pageError = nil
        defer {
            if requestedGeneration == generation { list.isLoadingMore = false }
        }

        do {
            let response = try await api.getClientFavorites(page: requestedPage, limit: Self.pageSize)
            guard requestedGeneration == generation else { return }
            list.append(
                page: rows(from: response.data.experts, requestSerial: serial),
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
                _ = list.remove(key: expert.pagingKey)
            }
            return Task {}
        }

        let removed = withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            list.remove(key: expert.pagingKey)
        }
        // From here no list response may bring the row back until the DELETE ends (WR-11).
        pendingRemovals.insert(expert.pagingKey)

        return Task { [weak self] in
            guard let self else { return }
            defer { self.pendingRemovals.remove(expert.pagingKey) }
            do {
                _ = try await self.api.removeFavorite(expertId: expertId)
                // A list request that started before this moment may still carry the row.
                self.removalFinishedAt[expert.pagingKey] = self.requestSerial
                // Every later row moved up one place on the server; see
                // `loadNextPageIfNeeded`. No effect once every page is loaded.
                self.list.markStale()
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

    // MARK: - Removal filter (WR-11)

    /// Numbers a list request as it starts. See `removalFinishedAt`.
    private func beginListRequest() -> Int {
        requestSerial += 1
        return requestSerial
    }

    /// Maps a list response and drops every expert the user removed while the
    /// request was in flight, so a response that predates the `DELETE` cannot
    /// bring the row back.
    private func rows(from items: [FavoriteExpertItem], requestSerial serial: Int) -> [FavoriteExpert] {
        items.map(Self.map).filter { !isRemoved($0.pagingKey, requestSerial: serial) }
    }

    private func isRemoved(_ key: UUID, requestSerial serial: Int) -> Bool {
        if pendingRemovals.contains(key) { return true }
        guard let finishedAt = removalFinishedAt[key] else { return false }
        return finishedAt >= serial
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
