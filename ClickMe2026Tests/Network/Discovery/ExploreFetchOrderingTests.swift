//
//  ExploreFetchOrderingTests.swift
//  ClickMe2026Tests
//
//  WR-08: two `/client/home` fetches can overlap (a chip tap while the first
//  load or a refresh is still in flight). The response of the newest fetch
//  must win whatever order the responses land in.
//
//  The responses are held by a test-local `URLProtocol` that parks no thread:
//  `startLoading` stores the request and the test answers it later, in any
//  order. `MockURLProtocol` answers inside `startLoading`, so it cannot hold
//  two requests at once.
//

import Foundation
import Testing
@testable import ClickMe2026

// MARK: - Held responses

/// Holds every `/client/home` request until the test answers it. Any other
/// path gets a 404 straight away (the view model also reads `/client/bookings`).
private final class HeldHomeProtocol: URLProtocol, @unchecked Sendable {

    private static let lock = NSLock()
    nonisolated(unsafe) private static var held: [HeldHomeProtocol] = []

    static func reset() {
        lock.withLock { held = [] }
    }

    /// How many `/client/home` requests are waiting for an answer.
    static var heldCount: Int {
        lock.withLock { held.count }
    }

    /// Answers the oldest held request for which `matches` is true. Returns false when none matches.
    @discardableResult
    static func release(where matches: (URLRequest) -> Bool, body: Data) -> Bool {
        let target: HeldHomeProtocol? = lock.withLock {
            guard let index = held.firstIndex(where: { matches($0.request) }) else { return nil }
            return held.remove(at: index)
        }
        guard let target else { return false }
        target.finish(status: 200, body: body)
        return true
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if request.url?.path.hasSuffix("/client/home") == true {
            Self.lock.withLock { Self.held.append(self) }
        } else {
            finish(status: 404, body: Data(#"{"status":"error","message":"nope"}"#.utf8))
        }
    }

    override func stopLoading() {}

    private func finish(status: Int, body: Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

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

@MainActor
private func makeHeldAPI() -> ClickMeAPI {
    HeldHomeProtocol.reset()
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [HeldHomeProtocol.self]
    let service = NetworkService(session: URLSession(configuration: config))
    return ClickMeAPI(baseURL: APITestFactory.baseURL, service: service)
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

@Suite("Explore · overlapping /client/home fetches (WR-08)", .serialized)
@MainActor
struct ExploreFetchOrderingTests {

    @Test("a slower unfiltered response never overwrites the filtered feed that landed first")
    func filteredResponseLandingFirstStays() async throws {
        let viewModel = ExploreClientViewModel(api: makeHeldAPI())

        // Fetch 1: the screen's load, no filter.
        let firstLoad = Task { await viewModel.load() }
        try #require(await waitUntil { HeldHomeProtocol.heldCount == 1 })

        // Fetch 2: the user taps the "Technology" chip before fetch 1 lands.
        viewModel.applySelectedCategories(["technology"])
        try #require(await waitUntil { HeldHomeProtocol.heldCount == 2 })

        // The filtered response lands first.
        HeldHomeProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered)
        try #require(await waitUntil { viewModel.expertsState == .loaded })
        #expect(viewModel.experts.count == 1)

        // The slower unfiltered response lands second and must be dropped.
        HeldHomeProtocol.release(where: { !OrderingFixture.isFiltered($0) }, body: OrderingFixture.unfiltered)
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
        try #require(await waitUntil { HeldHomeProtocol.heldCount == 1 })
        viewModel.applySelectedCategories(["technology"])
        try #require(await waitUntil { HeldHomeProtocol.heldCount == 2 })

        // The unfiltered response lands first. It belongs to a fetch that is no longer the newest.
        HeldHomeProtocol.release(where: { !OrderingFixture.isFiltered($0) }, body: OrderingFixture.unfiltered)
        await firstLoad.value

        #expect(viewModel.experts.isEmpty)
        #expect(viewModel.categoriesState == .loading)
        #expect(viewModel.expertsState == .loading)
        #expect(viewModel.featuredTopicsState == .loading)

        HeldHomeProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered)
        try #require(await waitUntil { viewModel.expertsState == .loaded })

        #expect(viewModel.experts.count == 1)
        #expect(viewModel.categories.first?.isSelected == true)
    }

    @Test("a refresh started over a pending filter fetch asks for the filter and wins")
    func refreshOverPendingFilterKeepsFilter() async throws {
        let viewModel = ExploreClientViewModel(api: makeHeldAPI())

        viewModel.applySelectedCategories(["technology"])
        try #require(await waitUntil { HeldHomeProtocol.heldCount == 1 })
        let refresh = Task { await viewModel.reload() }
        try #require(await waitUntil { HeldHomeProtocol.heldCount == 2 })

        // Both requests carry the filter, so both bodies are the filtered feed.
        #expect(HeldHomeProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered))
        #expect(HeldHomeProtocol.release(where: OrderingFixture.isFiltered, body: OrderingFixture.filtered))
        await refresh.value
        try #require(await waitUntil { viewModel.expertsState == .loaded })

        #expect(viewModel.experts.count == 1)
        #expect(viewModel.selectedCategorySlugs == ["technology"])
    }
}
