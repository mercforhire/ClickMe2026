//
//  SearchExpertViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SearchExpertViewModel: ObservableObject {


    // MARK: View state
    @Published var searchText: String = "" {
        didSet { onSearchTextChanged() }
    }

    /// Slug (from `/categories`) of the currently-selected category chip.
    /// Empty string means the "All" chip is active — no filter applied.
    /// Passed straight through to `/experts/search?category=<slug>`.
    @Published var selectedCategorySlug: String = "" {
        didSet { onCategoryChanged() }
    }

    @Published var sortOption: String {
        didSet { onSortChanged() }
    }
    @Published var showSortPicker: Bool
    @Published var glowPulse: Bool

    // MARK: Data
    @Published var experts: [ExpertSearchResult] = []
    @Published var categories: [Category] = []
    @Published var state: LoadState = .idle

    /// Sort options shown in the confirmation dialog. Maps to
    /// `/experts/search?sort=` via `sortValue(for:)`.
    let sortOptions: [String]

    // MARK: Dependencies
    private let api: ClickMeAPI
    private let categoryStore: CategoryStore

    // MARK: Async plumbing
    private var searchTask: Task<Void, Never>?
    private static let searchDebounce: Duration = .milliseconds(300)

    // MARK: Inits

    init(
        api: ClickMeAPI = .shared,
        categoryStore: CategoryStore = .shared,
        selectedCategorySlug: String = "",
        sortOption: String = "Most popular",
        showSortPicker: Bool = false,
        glowPulse: Bool = false,
        sortOptions: [String] = ["Most popular", "Highest rated"]
    ) {
        self.api = api
        self.categoryStore = categoryStore
        self.selectedCategorySlug = selectedCategorySlug
        self.sortOption = sortOption
        self.showSortPicker = showSortPicker
        self.glowPulse = glowPulse
        self.sortOptions = sortOptions
    }

    /// Preview seam — bypasses the network and installs canned results as if
    /// a search had already succeeded.
    init(previewExperts: [ExpertSearchResult], previewCategories: [Category] = []) {
        self.api = .shared
        self.categoryStore = .shared
        self.experts = previewExperts
        self.categories = previewCategories
        self.state = .loaded
        self.selectedCategorySlug = ""
        self.sortOption = "Most popular"
        self.showSortPicker = false
        self.glowPulse = false
        self.sortOptions = ["Most popular", "Highest rated"]
    }

    // MARK: Derived

    /// True only after a load completes and the server returned nothing —
    /// distinguishes "no results" from "still loading" or "error".
    var showEmpty: Bool {
        if case .loaded = state, experts.isEmpty { return true }
        return false
    }

    // MARK: - Load

    /// Fetches the initial results plus the category-chip vocabulary.
    /// Category load is fire-and-forget so a slow response doesn't block
    /// results appearing.
    func load() async {
        Task { [weak self] in await self?.loadCategories() }
        await performSearch(query: trimmedQuery)
    }

    /// Pull-to-refresh handler.
    func reload() async {
        searchTask?.cancel()
        await load()
    }

    /// Populates the chip vocabulary from `CategoryStore` (disk-cached,
    /// 1-week TTL). Failures are swallowed — the "All" chip still works
    /// without any category list.
    func loadCategories() async {
        do {
            categories = try await categoryStore.fetch()
        } catch {
            categories = []
        }
    }

    // MARK: - Search

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func onSearchTextChanged() {
        searchTask?.cancel()
        let query = trimmedQuery
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: Self.searchDebounce)
            if Task.isCancelled { return }
            await self?.performSearch(query: query)
        }
    }

    private func onSortChanged() {
        rerunSearchImmediately()
    }

    private func onCategoryChanged() {
        rerunSearchImmediately()
    }

    /// Cancels any in-flight/debounced search and fires a fresh one with
    /// the current query + filters. Used for chip and sort taps where the
    /// user expects an instant response.
    private func rerunSearchImmediately() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            await self.performSearch(query: self.trimmedQuery)
        }
    }

    private func performSearch(query: String) async {
        state = .loading
        do {
            let response = try await api.searchExperts(
                q: query,
                category: selectedCategorySlug.isEmpty ? nil : selectedCategorySlug,
                sort: Self.sortValue(for: sortOption)
            )
            experts = response.data.experts.map(Self.map)
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    // MARK: - Mapping helpers

    /// Maps the UI-visible sort label onto the API's accepted values
    /// (`relevance` · `rating`).
    private static func sortValue(for option: String) -> String {
        switch option {
        case "Highest rated": return "rating"
        default:              return "relevance"
        }
    }

    private static func map(_ item: ExpertSearchResultItem) -> ExpertSearchResult {
        ExpertSearchResult(
            expertId: item.expertId,
            name: item.fullName ?? "Expert",
            title: item.headline ?? "",
            // `/experts/search` doesn't return a bio field per row.
            bio: "",
            rating: item.avgRating ?? 0,
            imageURL: item.avatarUrl ?? "",
            tags: item.expertiseTags ?? []
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
