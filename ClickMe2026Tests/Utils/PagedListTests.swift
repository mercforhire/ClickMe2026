//
//  PagedListTests.swift
//  ClickMe2026Tests
//
//  EXPL-05 / D-07: the paging rules shared by Favorites and Reviews. Pure value
//  type, no API.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Paged list")
struct PagedListTests {

    private struct Row: Equatable {
        let id: Int
        var label = ""
    }

    private func rows(_ ids: ClosedRange<Int>) -> [Row] {
        ids.map { Row(id: $0) }
    }

    private func makeList() -> PagedList<Row, Int> {
        PagedList<Row, Int>(key: \.id)
    }

    // MARK: - Pages

    @Test("a fresh list starts at page 1 with more to load")
    func freshList() {
        let list = makeList()
        #expect(list.items.isEmpty)
        #expect(list.nextPage == 1)
        #expect(list.hasMore)
        #expect(!list.isLoadingMore)
        #expect(list.pageError == nil)
        #expect(!list.isStale)
    }

    @Test("replace keeps the first occurrence of a duplicate key, sets nextPage 2 and keeps hasMore")
    func replaceDeduplicates() {
        var list = makeList()
        list.replace(
            withFirstPage: [Row(id: 1, label: "first"), Row(id: 2), Row(id: 1, label: "second")],
            hasMore: true
        )
        #expect(list.items.map(\.id) == [1, 2])
        #expect(list.items.first?.label == "first")
        #expect(list.nextPage == 2)
        #expect(list.hasMore)
    }

    @Test("replace clears the page error, the stale flag and the in-flight marker")
    func replaceClearsFlags() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)
        list.markStale()
        list.pageError = "offline"
        list.isLoadingMore = true

        list.replace(withFirstPage: rows(1...20), hasMore: true)

        #expect(!list.isStale)
        #expect(list.pageError == nil)
        #expect(!list.isLoadingMore)
    }

    @Test("append skips keys already present, keeps page order and advances nextPage")
    func appendSkipsKnownKeys() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)

        list.append(page: [Row(id: 20, label: "again")] + rows(21...25), hasMore: false)

        #expect(list.items.map(\.id) == Array(1...25))
        #expect(list.items[19].label == "")
        #expect(list.nextPage == 3)
        #expect(!list.hasMore)
    }

    @Test("append clears a page error but leaves the stale flag")
    func appendKeepsStale() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)
        list.markStale()
        list.pageError = "offline"

        list.append(page: rows(21...40), hasMore: true)

        #expect(list.pageError == nil)
        #expect(list.isStale)
    }

    @Test("an empty page with hasMore false ends the list")
    func emptyPageEnds() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)

        list.append(page: [], hasMore: false)

        #expect(list.items.count == 20)
        #expect(!list.hasMore)
        #expect(!list.shouldLoadMore(afterItemAt: 19))
    }

    @Test("an empty page ends the list even when the server still says hasMore")
    func emptyPageWithHasMoreStillEnds() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)

        list.append(page: [], hasMore: true)

        #expect(!list.hasMore)
    }

    @Test("an empty first page ends the list")
    func emptyFirstPage() {
        var list = makeList()
        list.replace(withFirstPage: [], hasMore: true)
        #expect(list.items.isEmpty)
        #expect(!list.hasMore)
    }

    @Test("markEnd stops paging and clears the page error")
    func markEnd() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)
        list.pageError = "offline"

        list.markEnd()

        #expect(!list.hasMore)
        #expect(list.pageError == nil)
    }

    @Test("reset returns to a fresh list")
    func reset() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)
        list.markStale()
        list.pageError = "offline"

        list.reset()

        #expect(list.items.isEmpty)
        #expect(list.nextPage == 1)
        #expect(list.hasMore)
        #expect(!list.isStale)
        #expect(list.pageError == nil)
    }

    // MARK: - Trigger

    @Test("shouldLoadMore is true only for the last 3 indices")
    func triggerWindow() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)

        #expect(!list.shouldLoadMore(afterItemAt: 0))
        #expect(!list.shouldLoadMore(afterItemAt: 16))
        #expect(list.shouldLoadMore(afterItemAt: 17))
        #expect(list.shouldLoadMore(afterItemAt: 18))
        #expect(list.shouldLoadMore(afterItemAt: 19))
        #expect(!list.shouldLoadMore(afterItemAt: 20))
        #expect(!list.shouldLoadMore(afterItemAt: -1))
    }

    @Test("shouldLoadMore is false when hasMore is false")
    func triggerStopsAtEnd() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: false)
        #expect(!list.shouldLoadMore(afterItemAt: 19))
    }

    @Test("shouldLoadMore is false while a page is loading")
    func triggerWaitsForLoad() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...20), hasMore: true)
        list.isLoadingMore = true
        #expect(!list.shouldLoadMore(afterItemAt: 19))
    }

    @Test("a short list triggers from its first row")
    func shortList() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...2), hasMore: true)
        #expect(list.shouldLoadMore(afterItemAt: 0))
        #expect(list.shouldLoadMore(afterItemAt: 1))
    }

    // MARK: - Rows

    @Test("remove returns the index and item, and insert puts it back there")
    func removeAndInsert() throws {
        var list = makeList()
        list.replace(withFirstPage: rows(1...5), hasMore: false)

        let result = list.remove(key: 3)
        let removed = try #require(result)
        #expect(removed.index == 2)
        #expect(removed.item.id == 3)
        #expect(list.items.map(\.id) == [1, 2, 4, 5])

        list.insert(removed.item, at: removed.index)
        #expect(list.items.map(\.id) == [1, 2, 3, 4, 5])
    }

    @Test("remove of an unknown key returns nil and changes nothing")
    func removeUnknown() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...3), hasMore: false)
        let result = list.remove(key: 99)
        #expect(result == nil)
        #expect(list.items.count == 3)
    }

    @Test("insert clamps the index and never duplicates a key")
    func insertClampsAndDeduplicates() {
        var list = makeList()
        list.replace(withFirstPage: rows(1...3), hasMore: false)

        list.insert(Row(id: 9), at: 50)
        list.insert(Row(id: 8), at: -4)
        list.insert(Row(id: 2), at: 0)

        #expect(list.items.map(\.id) == [8, 1, 2, 3, 9])
    }

    // MARK: - Stale flag

    @Test("markStale only counts while more pages remain")
    func staleNeedsMorePages() {
        var done = makeList()
        done.replace(withFirstPage: rows(1...5), hasMore: false)
        done.markStale()
        #expect(!done.isStale)

        var more = makeList()
        more.replace(withFirstPage: rows(1...20), hasMore: true)
        more.markStale()
        #expect(more.isStale)
    }
}
