//
//  PagedList.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The one paging rule shared by Favorites and the full reviews list (D-07).
///
/// A view model owns a `PagedList`, asks it `shouldLoadMore(afterItemAt:)` when
/// a row appears, then feeds the server page back through `replace(withFirstPage:hasMore:)`
/// or `append(page:hasMore:)`. The type holds no network code, so every rule can
/// be tested without a stub.
///
/// - The server envelope carries `has_more` and no total (RESEARCH Pitfall 3),
///   so the list stops on `hasMore == false`, never on a count.
/// - `Key` must be a server id. A row's own `id` is regenerated on every map
///   (RESEARCH Pitfall 5), so only a server id can spot the same expert arriving
///   on two adjacent pages after an offset shift.
/// - Items keep server order. On a duplicate key the first occurrence stays where
///   it is and the later one is dropped.
struct PagedList<Item, Key: Hashable> {

    // MARK: State

    private(set) var items: [Item] = []
    /// The page number the next fetch should request.
    private(set) var nextPage: Int = 1
    private(set) var hasMore: Bool = true
    /// True while a next-page fetch is in flight. Gates the scroll trigger.
    var isLoadingMore: Bool = false
    /// Text for the footer when a later page failed. The loaded rows stay.
    var pageError: String?
    /// Set when a row left the list while more pages remain: the server offsets
    /// moved, so the next paging trigger must restart at page 1 (RESEARCH Open Question 4).
    private(set) var isStale: Bool = false

    private let key: KeyPath<Item, Key>

    /// How close to the end a row must be to start the next fetch.
    static var triggerWindow: Int { 3 }

    init(key: KeyPath<Item, Key>) {
        self.key = key
    }

    // MARK: - Pages

    /// Installs page 1, dropping any duplicate key inside it. Clears the page
    /// error and the stale flag, and ends the in-flight marker.
    mutating func replace(withFirstPage page: [Item], hasMore: Bool) {
        items = deduplicated(page, excluding: [])
        nextPage = 2
        self.hasMore = page.isEmpty ? false : hasMore
        isLoadingMore = false
        pageError = nil
        isStale = false
    }

    /// Adds a later page after the rows already loaded, skipping keys already
    /// present. An empty page always ends the list, so a server that keeps
    /// saying `has_more` on an empty page cannot make the client loop.
    mutating func append(page: [Item], hasMore: Bool) {
        let known = Set(items.map { $0[keyPath: key] })
        items.append(contentsOf: deduplicated(page, excluding: known))
        nextPage += 1
        self.hasMore = page.isEmpty ? false : hasMore
        pageError = nil
    }

    /// Treats the list as complete (a 500 on a page past the last one is
    /// PostgREST's out-of-range answer, not a failure).
    mutating func markEnd() {
        hasMore = false
        pageError = nil
    }

    /// Flags the offsets as moved. No effect once every page is loaded, because
    /// then nothing is left to skip.
    mutating func markStale() {
        guard hasMore else { return }
        isStale = true
    }

    mutating func reset() {
        items = []
        nextPage = 1
        hasMore = true
        isLoadingMore = false
        pageError = nil
        isStale = false
    }

    // MARK: - Rows

    /// Removes the row with `key` and returns where it was, so a failed server
    /// call can put it back.
    @discardableResult
    mutating func remove(key target: Key) -> (index: Int, item: Item)? {
        guard let index = items.firstIndex(where: { $0[keyPath: key] == target }) else { return nil }
        return (index, items.remove(at: index))
    }

    /// Puts a row back at `index` (clamped to the list). A key already in the
    /// list is not inserted twice.
    mutating func insert(_ item: Item, at index: Int) {
        let target = item[keyPath: key]
        guard !items.contains(where: { $0[keyPath: key] == target }) else { return }
        items.insert(item, at: min(max(index, 0), items.count))
    }

    // MARK: - Trigger

    /// True when the row at `index` is one of the last `triggerWindow` rows and
    /// a fetch is both possible and not already running.
    func shouldLoadMore(afterItemAt index: Int) -> Bool {
        guard hasMore, !isLoadingMore else { return false }
        guard items.indices.contains(index) else { return false }
        return index >= items.count - Self.triggerWindow
    }

    // MARK: - Helpers

    private func deduplicated(_ page: [Item], excluding known: Set<Key>) -> [Item] {
        var seen = known
        return page.filter { seen.insert($0[keyPath: key]).inserted }
    }
}
