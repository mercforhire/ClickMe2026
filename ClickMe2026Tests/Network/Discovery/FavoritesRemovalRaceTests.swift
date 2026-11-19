//
//  FavoritesRemovalRaceTests.swift
//  ClickMe2026Tests
//
//  WR-11: (1) a list response that was requested before an unfavorite finished
//  must not bring the removed row back, and (2) the list revalidates after the
//  profile opened from it changed a favorite.
//
//  Responses are held by `HeldURLProtocol` so a test can land a list response
//  before, between or after the `DELETE`.
//

import Foundation
import Testing
@testable import ClickMe2026

private enum RaceFixture {

    nonisolated static func expertId(_ n: Int) -> String {
        "00000000-0000-4000-8000-" + String(format: "%012d", n)
    }

    nonisolated static func item(_ n: Int) -> String {
        """
        {"expert_id":"\(expertId(n))","full_name":"Expert \(n)","headline":null,"avatar_url":null,\
        "experience_years":null,"avg_rating":null,"total_reviews":null,"hourly_rate_amount":null,\
        "hourly_rate_currency":null,"expertise_tags":[],"is_favorite":true,"favorited_at":null}
        """
    }

    /// A single-page success envelope holding experts `ids`.
    nonisolated static func page(_ ids: [Int]) -> Data {
        Data(
            """
            {"status":"success","data":{"experts":[\(ids.map(item).joined(separator: ","))],\
            "pagination":{"current_page":1,"total_pages":1,"has_more":false}}}
            """.utf8
        )
    }

    nonisolated static func unfavorited(_ n: Int) -> Data {
        Data(#"{"status":"success","data":{"expert_id":"\#(expertId(n))","is_favorite":false}}"#.utf8)
    }

    nonisolated static let errorBody = Data(#"{"status":"error","message":"nope"}"#.utf8)

    nonisolated static func isList(_ request: URLRequest) -> Bool {
        request.httpMethod == "GET" && request.url?.path.hasSuffix("/client/favorites") == true
    }

    nonisolated static func isDelete(_ request: URLRequest) -> Bool {
        request.httpMethod == "DELETE" && request.url?.path.contains("/client/favorites/") == true
    }
}

/// Counts list requests behind a lock; the stub runs on a URL loading thread.
private final class ListCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func increment() { lock.withLock { count += 1 } }
    var value: Int { lock.withLock { count } }
}

extension HeldResponseTests {
    @Suite("Favorites · removal races and revalidation (WR-11)", .serialized)
    @MainActor
    struct FavoritesRemovalRaceTests {

        /// Loads experts 1, 2 and 3 with nothing held, then holds list requests and deletes.
        private func loadedViewModel(counter: ListCounter = ListCounter()) async -> FavoritesViewModel {
            HeldURLProtocol.configure(
                hold: { _ in false },
                otherwise: { request in
                    if RaceFixture.isList(request) {
                        counter.increment()
                        return (200, RaceFixture.page([1, 2, 3]))
                    }
                    return (404, RaceFixture.errorBody)
                }
            )
            let viewModel = FavoritesViewModel(api: HeldURLProtocol.makeAPI())
            await viewModel.load()
            return viewModel
        }

        private func holdListsAndDeletes() {
            HeldURLProtocol.setHold { RaceFixture.isList($0) || RaceFixture.isDelete($0) }
        }

        private func ids(_ viewModel: FavoritesViewModel) -> [Int] {
            viewModel.favorites.compactMap { row in
                row.expertId.flatMap { id in (1 ... 3).first { RaceFixture.expertId($0) == id.uuidString.lowercased() } }
            }
        }

        private func waitUntil(_ condition: () -> Bool) async -> Bool {
            for _ in 0 ..< 500 {
                if condition() { return true }
                try? await Task.sleep(for: .milliseconds(10))
            }
            return condition()
        }

        // MARK: - Optimistic remove against a refresh

        @Test("a refresh that lands while the DELETE is running does not bring the row back")
        func refreshLandingDuringDeleteKeepsRowRemoved() async throws {
            let viewModel = await loadedViewModel()
            #expect(ids(viewModel) == [1, 2, 3])
            holdListsAndDeletes()

            let refresh = Task { await viewModel.refresh() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            let removal = viewModel.removeFavorite(viewModel.favorites[0])
            try #require(await waitUntil { HeldURLProtocol.heldCount == 2 })

            // The list response was read before the DELETE and still has expert 1.
            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([1, 2, 3]))
            await refresh.value
            #expect(ids(viewModel) == [2, 3])

            HeldURLProtocol.release(where: RaceFixture.isDelete, body: RaceFixture.unfavorited(1))
            await removal.value
            #expect(ids(viewModel) == [2, 3])
            #expect(viewModel.apiError == nil)
        }

        @Test("a refresh requested before the DELETE ended and landing after it does not bring the row back")
        func refreshLandingAfterDeleteKeepsRowRemoved() async throws {
            let viewModel = await loadedViewModel()
            holdListsAndDeletes()

            let refresh = Task { await viewModel.refresh() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            let removal = viewModel.removeFavorite(viewModel.favorites[0])
            try #require(await waitUntil { HeldURLProtocol.heldCount == 2 })

            HeldURLProtocol.release(where: RaceFixture.isDelete, body: RaceFixture.unfavorited(1))
            await removal.value
            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([1, 2, 3]))
            await refresh.value

            #expect(ids(viewModel) == [2, 3])
        }

        @Test("a refresh requested after the DELETE ended shows what the server says, even the removed expert")
        func refreshAfterDeleteTrustsTheServer() async throws {
            let viewModel = await loadedViewModel()
            HeldURLProtocol.setHold(RaceFixture.isDelete)

            let removal = viewModel.removeFavorite(viewModel.favorites[0])
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            HeldURLProtocol.release(where: RaceFixture.isDelete, body: RaceFixture.unfavorited(1))
            await removal.value
            #expect(ids(viewModel) == [2, 3])

            // The expert was favorited again from another screen; the list request now answers with them.
            await viewModel.refresh()

            #expect(ids(viewModel) == [1, 2, 3])
        }

        @Test("a failed DELETE puts the row back after a refresh landed in between, and raises the alert")
        func failedDeleteRollsBackAfterRefresh() async throws {
            let viewModel = await loadedViewModel()
            holdListsAndDeletes()

            let refresh = Task { await viewModel.refresh() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            let removal = viewModel.removeFavorite(viewModel.favorites[0])
            try #require(await waitUntil { HeldURLProtocol.heldCount == 2 })

            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([1, 2, 3]))
            await refresh.value
            #expect(ids(viewModel) == [2, 3])

            HeldURLProtocol.release(where: RaceFixture.isDelete, status: 500, body: RaceFixture.errorBody)
            await removal.value

            #expect(ids(viewModel) == [1, 2, 3])
            #expect(viewModel.apiError != nil)
        }

        // MARK: - Revalidation after the profile changed a favorite

        @Test("load() on a loaded list makes no request until the profile changed a favorite")
        func loadedListIsNotRefetched() async {
            let counter = ListCounter()
            let viewModel = await loadedViewModel(counter: counter)
            #expect(counter.value == 1)

            await viewModel.load()

            #expect(counter.value == 1)
        }

        @Test("when the profile changes a favorite, the list revalidates quietly and follows the server")
        func profileChangeRevalidatesList() async throws {
            let viewModel = await loadedViewModel()
            HeldURLProtocol.setHold(RaceFixture.isList)

            // The user unfavorited expert 1 on the profile.
            let revalidation = viewModel.noteProfileFavoriteChanged()
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })

            // The rows stay on screen while the request runs.
            #expect(viewModel.state == .loaded)
            #expect(ids(viewModel) == [1, 2, 3])

            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([2, 3]))
            await revalidation.value

            #expect(ids(viewModel) == [2, 3])
            #expect(viewModel.state == .loaded)
            #expect(viewModel.apiError == nil)
        }

        @Test("a toggle that finishes after the list's task already ran still revalidates the list (WR-13)")
        func toggleFinishingAfterPopStillRevalidates() async throws {
            let counter = ListCounter()
            let viewModel = await loadedViewModel(counter: counter)
            // The user tapped the heart and went back at once. The list's `.task` ran then, found
            // nothing to do, and the toggle finished afterwards.
            await viewModel.load()
            #expect(counter.value == 1)

            HeldURLProtocol.setHold(RaceFixture.isList)
            viewModel.noteProfileFavoriteChanged()
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([2, 3]))
            try #require(await waitUntil { ids(viewModel) == [2, 3] })

            #expect(viewModel.apiError == nil)
        }

        @Test("a refresh that started before the profile change cannot clear the flag (WR-13)")
        func olderRefreshResponseDoesNotClearTheFlag() async throws {
            let counter = ListCounter()
            let viewModel = await loadedViewModel(counter: counter)
            HeldURLProtocol.setHold(RaceFixture.isList)

            // A pull-to-refresh is in flight; the profile toggles and notes the change meanwhile.
            let pull = Task { await viewModel.refresh() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            viewModel.noteProfileFavoriteChanged()

            // The older response still lists expert 1. It is applied, but it may predate the change,
            // so the refresh asks again.
            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([1, 2, 3]))
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            #expect(ids(viewModel) == [1, 2, 3])

            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([2, 3]))
            await pull.value
            #expect(ids(viewModel) == [2, 3])

            // The flag is clear now: the list's next `.task` makes no request.
            HeldURLProtocol.setHold { _ in false }
            let before = counter.value
            await viewModel.load()
            #expect(counter.value == before)
        }

        @Test("a failed revalidation keeps the rows, raises no alert and tries again on the next load()")
        func failedRevalidationIsQuietAndRetried() async throws {
            let viewModel = await loadedViewModel()
            HeldURLProtocol.setHold(RaceFixture.isList)

            let first = viewModel.noteProfileFavoriteChanged()
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            HeldURLProtocol.release(where: RaceFixture.isList, status: 500, body: RaceFixture.errorBody)
            await first.value

            #expect(ids(viewModel) == [1, 2, 3])
            #expect(viewModel.state == .loaded)
            #expect(viewModel.apiError == nil)

            let second = Task { await viewModel.load() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            HeldURLProtocol.release(where: RaceFixture.isList, body: RaceFixture.page([3]))
            await second.value

            #expect(ids(viewModel) == [3])
        }

        @Test("a revalidation clears the flag, so the next load() makes no request")
        func revalidationClearsTheFlag() async throws {
            let counter = ListCounter()
            let viewModel = await loadedViewModel(counter: counter)

            await viewModel.noteProfileFavoriteChanged().value
            #expect(counter.value == 2)

            await viewModel.load()
            #expect(counter.value == 2)
        }
    }
}
