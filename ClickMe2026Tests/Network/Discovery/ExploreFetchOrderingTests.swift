//
//  ExploreFetchOrderingTests.swift
//  ClickMe2026Tests
//
//  WR-08: two `/client/home` fetches can overlap (a chip tap while the first
//  load or a refresh is still in flight). The response of the newest fetch
//  must win whatever order the responses land in.
//
//  The responses are held by `HeldURLProtocol`, which parks no thread: the
//  test answers each held request later, in any order. `MockURLProtocol`
//  answers inside `startLoading`, so it cannot hold two requests at once.
//

import Foundation
import Testing
@testable import ClickMe2026

// MARK: - Fixtures

private enum OrderingFixture {

    nonisolated static let experts = [
        "11111111-1111-4111-8111-111111111111",
        "33333333-3333-4333-8333-333333333333"
    ]

    nonisolated static func expert(_ id: String) -> String {
        """
        {"expert_id":"\(id)","full_name":"Ada Lovelace","title":null,"profile_image_url":null,\
        "rating":4.5,"review_count":2,"years_experience":3,"expertise_tags":["Swift"],"is_favorite":false}
        """
    }

    /// The `/client/home` envelope with one trending category (`technology`) and the given experts.
    nonisolated static func envelope(expertIds: [String]) -> Data {
        Data(
            """
            {"status":"success","data":{"trending_categories":[{"id":"technology","name":"Technology",\
            "icon_name":"cpu","color_accent":"#00FF00"}],\
            "recommended_experts":[\(expertIds.map(expert).joined(separator: ","))],"featured_topics":[]}}
            """.utf8
        )
    }

    /// Every expert: the answer to a request with no filter.
    nonisolated static var unfiltered: Data { envelope(expertIds: experts) }

    /// One expert: the answer to `?category=technology`.
    nonisolated static var filtered: Data { envelope(expertIds: [experts[0]]) }

    nonisolated static func isFiltered(_ request: URLRequest) -> Bool {
        request.url?.query?.contains("category=technology") == true
    }
}

/// Holds every `/client/home` request. Any other path (the view model also reads
/// `/client/bookings`) gets a 404 straight away.
@MainActor
private func makeHeldAPI() -> ClickMeAPI {
    HeldURLProtocol.configure(
        hold: { $0.url?.path.hasSuffix("/client/home") == true },
        otherwise: { _ in (404, Data(#"{"status":"error","message":"nope"}"#.utf8)) }
    )
    return HeldURLProtocol.makeAPI()
}

/// Polls every 10 ms, for up to 5 s, until `condition` holds.
@MainActor
private func waitUntil(_ condition: () -> Bool) async -> Bool {
    for _ in 0..<500 {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}

extension HeldResponseTests {
    @Suite("Explore · overlapping /client/home fetches (WR-08)", .serialized)
    @MainActor
    struct ExploreFetchOrderingTests {

        @Test("a slower unfiltered response never overwrites the filtered feed that landed first")
        func filteredResponseLandingFirstStays() async throws {
            let viewModel = ExploreClientViewModel(api: makeHeldAPI())

            // Fetch 1: the screen's load, no filter.
            let firstLoad = Task { await viewModel.load() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })

            // Fetch 2: the user taps the "Technology" chip before fetch 1 lands.
            viewModel.applySelectedCategories(["technology"])
            try #require(await waitUntil { HeldURLProtocol.heldCount == 2 })

            // The filtered response lands first.
            HeldURLProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered)
            try #require(await waitUntil { viewModel.expertsState == .loaded })
            #expect(viewModel.experts.count == 1)

            // The slower unfiltered response lands second and must be dropped.
            HeldURLProtocol.release(where: { !OrderingFixture.isFiltered($0) }, body: OrderingFixture.unfiltered)
            await firstLoad.value

            #expect(viewModel.experts.count == 1)
            #expect(viewModel.categoriesState == .loaded)
            #expect(viewModel.expertsState == .loaded)
            #expect(viewModel.featuredTopicsState == .loaded)
            #expect(viewModel.selectedCategorySlugs == ["technology"])
            #expect(viewModel.categories.first?.isSelected == true)
        }

        @Test("an older response that lands first leaves the skeletons up until the newest fetch answers")
        func olderResponseLandingFirstIsDropped() async throws {
            let viewModel = ExploreClientViewModel(api: makeHeldAPI())

            let firstLoad = Task { await viewModel.load() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            viewModel.applySelectedCategories(["technology"])
            try #require(await waitUntil { HeldURLProtocol.heldCount == 2 })

            // The unfiltered response lands first. It belongs to a fetch that is no longer the newest.
            HeldURLProtocol.release(where: { !OrderingFixture.isFiltered($0) }, body: OrderingFixture.unfiltered)
            await firstLoad.value

            #expect(viewModel.experts.isEmpty)
            #expect(viewModel.categoriesState == .loading)
            #expect(viewModel.expertsState == .loading)
            #expect(viewModel.featuredTopicsState == .loading)

            HeldURLProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered)
            try #require(await waitUntil { viewModel.expertsState == .loaded })

            #expect(viewModel.experts.count == 1)
            #expect(viewModel.categories.first?.isSelected == true)
        }

        @Test("a refresh started over a pending filter fetch asks for the filter and wins")
        func refreshOverPendingFilterKeepsFilter() async throws {
            let viewModel = ExploreClientViewModel(api: makeHeldAPI())

            viewModel.applySelectedCategories(["technology"])
            try #require(await waitUntil { HeldURLProtocol.heldCount == 1 })
            let refresh = Task { await viewModel.reload() }
            try #require(await waitUntil { HeldURLProtocol.heldCount == 2 })

            // Both requests carry the filter, so both bodies are the filtered feed.
            #expect(HeldURLProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered))
            #expect(HeldURLProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered))
            await refresh.value
            try #require(await waitUntil { viewModel.expertsState == .loaded })

            #expect(viewModel.experts.count == 1)
            #expect(viewModel.selectedCategorySlugs == ["technology"])
        }
    }
}
