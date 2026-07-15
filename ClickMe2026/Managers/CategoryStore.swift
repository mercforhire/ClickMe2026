//
//  CategoryStore.swift
//  ClickMe2026
//
//  Wraps `GET /categories` with a persistent disk cache. Categories are
//  reference vocab that changes rarely, so we serve from cache and only
//  refetch when the cached copy is older than a week.
//

import Foundation

@MainActor
final class CategoryStore: ObservableObject {

    static let shared = CategoryStore()

    // MARK: Config

    /// Cache stays fresh for one week. After that, `fetch()` will refetch
    /// from the network and rewrite the cache.
    private static let staleAfter: TimeInterval = 7 * 24 * 60 * 60

    // MARK: Storage keys

    private let defaults: UserDefaults
    private let dataKey = "clickme.categories.cache.data"
    private let fetchedAtKey = "clickme.categories.cache.fetchedAt"

    // MARK: In-memory cache (avoids re-decoding on repeat reads)

    private var cachedCategories: [Category]?

    private var api: ClickMeAPI { ClickMeAPI.shared }

    // MARK: Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: Public

    /// Returns categories, preferring a fresh disk cache (<1 week old) and
    /// otherwise refetching from `/categories` and rewriting the cache.
    func fetch() async throws -> [Category] {
        if let fresh = loadFreshCache() {
            return fresh
        }
        return try await refresh()
    }

    /// Bypasses the cache and refetches unconditionally. Rewrites the
    /// on-disk cache with the fresh response.
    @discardableResult
    func refresh() async throws -> [Category] {
        let response = try await api.getAllCategories()
        let list = response.data.categories
        save(list)
        return list
    }

    // MARK: Cache read

    private func loadFreshCache() -> [Category]? {
        if let cached = cachedCategories, isFresh { return cached }

        guard isFresh,
              let data = defaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode([Category].self, from: data)
        else { return nil }

        cachedCategories = decoded
        return decoded
    }

    private var isFresh: Bool {
        let ts = defaults.double(forKey: fetchedAtKey)
        guard ts > 0 else { return false }
        return Date().timeIntervalSince1970 - ts < Self.staleAfter
    }

    // MARK: Cache write

    private func save(_ categories: [Category]) {
        cachedCategories = categories
        if let data = try? JSONEncoder().encode(categories) {
            defaults.set(data, forKey: dataKey)
            defaults.set(Date().timeIntervalSince1970, forKey: fetchedAtKey)
        }
    }
}
