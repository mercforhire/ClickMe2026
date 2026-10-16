//
//  ClientTransactionsViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Backs `ClientTransactionsView` — the full-screen paginated payment
/// history. Loads one page at a time from `GET /client/transactions`,
/// advancing to the next page when the tail row scrolls into view.
///
/// Deals with the pagination footgun documented in spec §7:
/// requesting a page past the last one returns HTTP 500, not an empty
/// list. `loadNextPageIfNeeded` treats a 500 on any `page > 1` as
/// end-of-list (silently flips `hasMore` to false), so users never see
/// a spurious error toast just because they scrolled to the bottom.
/// A 500 on `page == 1` is still a real error and surfaces via
/// `loadState`.
@MainActor
final class ClientTransactionsViewModel: ObservableObject {

    // MARK: State

    @Published var items: [ClientTransactionItem]
    @Published var loadState: LoadState
    /// True while a next-page fetch is in flight — gates the scroll
    /// trigger so we don't fire the same request twice back-to-back.
    @Published var isLoadingMore: Bool
    /// Non-real errors from a next-page fetch. Rendered inline as a
    /// small retry footer without invalidating already-loaded rows.
    /// A 500 on any `page > 1` deliberately does NOT populate this —
    /// it's treated as end-of-list per spec §7.
    @Published var pageError: String?
    /// Total across all pages, as reported by the server. Safe to show
    /// as a screen header count.
    @Published var totalCount: Int

    private var currentPage: Int
    private var hasMore: Bool
    private let limit: Int

    // MARK: Dependencies
    private let api: ClickMeAPI

    init(api: ClickMeAPI = .shared, pageSize: Int = 20) {
        self.items = []
        self.loadState = .idle
        self.isLoadingMore = false
        self.pageError = nil
        self.totalCount = 0
        self.currentPage = 0
        self.hasMore = true
        self.limit = pageSize
        self.api = api
    }

    /// Preview seam — installs canned data as if the first page had
    /// already loaded successfully.
    static func previewSeed(
        items: [ClientTransactionItem],
        totalCount: Int? = nil,
        hasMore: Bool = false
    ) -> ClientTransactionsViewModel {
        let vm = ClientTransactionsViewModel()
        vm.items = items
        vm.loadState = .loaded
        vm.totalCount = totalCount ?? items.count
        vm.currentPage = 1
        vm.hasMore = hasMore
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips if we've already loaded page 1 (preview seed
    /// or previous fetch on the same VM instance).
    func loadFirstPageIfNeeded() async {
        if case .loaded = loadState { return }
        if currentPage > 0 { return }
        await loadFirstPage()
    }

    func reload() async {
        currentPage = 0
        hasMore = true
        items = []
        pageError = nil
        totalCount = 0
        await loadFirstPage()
    }

    private func loadFirstPage() async {
        loadState = .loading
        do {
            let response = try await api.getClientTransactions(page: 1, limit: limit)
            items = response.data.transactions
            currentPage = 1
            hasMore = response.data.pagination.hasMoreOrDerived
            totalCount = response.data.pagination.totalCount ?? items.count
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    /// Fires from each row's `.task` — advances to the next page when
    /// the visible row is within the last 3 loaded rows. Fetch is
    /// gated on `isLoadingMore` + `hasMore` + `.loaded`; `pageError`
    /// deliberately does NOT gate, so a retry after failure just runs
    /// through the same guard.
    ///
    /// **Pagination-500-as-end handling (spec §7):** a 500 on any
    /// `page > 1` is silently swallowed and we flip `hasMore = false`
    /// so the list stops trying. This is the PostgREST out-of-range
    /// behavior the backend flags as systemic across the API — not
    /// specific to this endpoint.
    func loadNextPageIfNeeded(currentItem: ClientTransactionItem) async {
        guard !isLoadingMore, hasMore, case .loaded = loadState else { return }
        guard let index = items.firstIndex(of: currentItem),
              index >= items.count - 3
        else { return }

        isLoadingMore = true
        pageError = nil
        defer { isLoadingMore = false }

        let requestedPage = currentPage + 1
        do {
            let response = try await api.getClientTransactions(page: requestedPage, limit: limit)
            items.append(contentsOf: response.data.transactions)
            currentPage = requestedPage
            hasMore = response.data.pagination.hasMoreOrDerived
            if let total = response.data.pagination.totalCount {
                totalCount = total
            }
        } catch {
            // Spec §7: PostgREST returns 500 for out-of-range offsets.
            // Treat any 500 on page > 1 as "end of list, not an error"
            // — swallow silently, stop paging, no user-visible toast.
            if requestedPage > 1,
               case let NetworkError.httpError(status, _) = error,
               status == 500 {
                hasMore = false
                return
            }
            pageError = error.userMessage
        }
    }

    /// True when we've loaded at least one page and there are no rows
    /// to render. Drives the empty-state view.
    var isEmptyResult: Bool {
        if case .loaded = loadState { return items.isEmpty }
        return false
    }
}
