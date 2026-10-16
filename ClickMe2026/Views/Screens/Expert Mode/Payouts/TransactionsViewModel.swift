//
//  TransactionsViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Backs the full-screen paginated earnings ledger. Loads one page at a
/// time from `GET /expert/earnings/transactions`, advancing to the next
/// page when the tail row of the current list becomes visible (see
/// `loadNextPageIfNeeded`).
@MainActor
final class TransactionsViewModel: ObservableObject {

    // MARK: State

    @Published var items: [EarningsTransactionItem]
    @Published var loadState: LoadState
    /// True while a next-page fetch is in flight — used to gate the
    /// scroll-triggered load so we don't fire the same request twice.
    @Published var isLoadingMore: Bool
    /// Set on next-page failure so the tail row can show a small
    /// "Retry" affordance without invalidating already-loaded rows.
    @Published var pageError: String?

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
        self.currentPage = 0
        self.hasMore = true
        self.limit = pageSize
        self.api = api
    }

    /// Preview seam — installs canned data as if the first page had
    /// already loaded.
    static func previewSeed(
        items: [EarningsTransactionItem],
        hasMore: Bool = false
    ) -> TransactionsViewModel {
        let vm = TransactionsViewModel()
        vm.items = items
        vm.loadState = .loaded
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
        await loadFirstPage()
    }

    private func loadFirstPage() async {
        loadState = .loading
        do {
            let response = try await api.getEarningsTransactions(page: 1, limit: limit)
            items = response.data.transactions
            currentPage = 1
            hasMore = response.data.pagination.hasMoreOrDerived
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    /// Called from the tail-row `.onAppear` — fires the next-page fetch
    /// unless we're already loading, out of pages, or the first page
    /// hasn't landed yet. Silent on failure aside from `pageError`; the
    /// already-loaded rows stay put.
    func loadNextPageIfNeeded(currentItem: EarningsTransactionItem) async {
        guard !isLoadingMore, hasMore, case .loaded = loadState else { return }
        // Only trigger when the tail row becomes visible — the small
        // buffer (last 3 rows) gives the fetch some headroom before the
        // user hits the bottom.
        guard let index = items.firstIndex(of: currentItem),
              index >= items.count - 3
        else { return }

        isLoadingMore = true
        pageError = nil
        defer { isLoadingMore = false }

        do {
            let response = try await api.getEarningsTransactions(page: currentPage + 1, limit: limit)
            items.append(contentsOf: response.data.transactions)
            currentPage += 1
            hasMore = response.data.pagination.hasMoreOrDerived
        } catch {
            pageError = error.userMessage
        }
    }

    /// True when we've loaded at least one page and there are no rows
    /// to show — drives an empty state on the view.
    var isEmptyResult: Bool {
        if case .loaded = loadState {
            return items.isEmpty
        }
        return false
    }
}
