//
//  CategoriesModalViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class CategoriesModalViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: View state
    @Published var state: LoadState = .idle
    @Published var searchText: String = ""
    @Published var categories: [Category] = []
    @Published var selectedIds: Set<String> = []

    private let store: CategoryStore

    init(
        store: CategoryStore = .shared,
        categories: [Category] = [],
        selectedIds: Set<String> = [],
        state: LoadState = .idle
    ) {
        self.store = store
        self.categories = categories
        self.selectedIds = selectedIds
        self.state = state
    }

    // MARK: Derived

    /// Client-side, case-insensitive substring filter over the loaded set.
    /// Search is deliberately front-end only — there is no server search.
    var filtered: [Category] {
        guard !searchText.isEmpty else { return categories }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func isSelected(_ category: Category) -> Bool {
        selectedIds.contains(category.id)
    }

    // MARK: Actions

    /// Loads categories from the store. Idempotent — skips if already loaded.
    func load() async {
        if case .loaded = state { return }
        state = .loading
        do {
            categories = try await store.fetch()
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Forces a cache-busting refetch (used by the retry button).
    func retry() async {
        state = .loading
        do {
            categories = try await store.refresh()
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func toggle(_ category: Category) {
        if selectedIds.contains(category.id) {
            selectedIds.remove(category.id)
        } else {
            selectedIds.insert(category.id)
        }
    }

    // MARK: Helpers

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
