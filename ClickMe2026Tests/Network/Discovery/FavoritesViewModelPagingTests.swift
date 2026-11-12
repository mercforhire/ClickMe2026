//
//  FavoritesViewModelPagingTests.swift
//  ClickMe2026Tests
//
//  EXPL-05 / D-07: Favorites loads `GET /client/favorites` in pages of 20,
//  fetches the next page when one of the last 3 rows appears, stops on
//  `has_more` false, and never shows the same expert twice. The favorites
//  envelope has `current_page`, `total_pages` and `has_more`, and no total.
//

import Foundation
import Testing
@testable import ClickMe2026

// MARK: - Fixtures

private enum FavoritesFixture {

    /// What the stubbed server answers for one `page` value.
    enum Reply: Sendable {
        case page(Data)
        case status(Int)
        case failure(URLError.Code)
    }

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

    /// One success envelope holding experts `ids` as page `number`.
    nonisolated static func page(_ ids: [Int], number: Int, hasMore: Bool, totalPages: Int = 2) -> Data {
        Data(
            """
            {"status":"success","data":{"experts":[\(ids.map(item).joined(separator: ","))],\
            "pagination":{"current_page":\(number),"total_pages":\(totalPages),"has_more":\(hasMore)}}}
            """.utf8
        )
    }

    nonisolated static func page(_ ids: ClosedRange<Int>, number: Int, hasMore: Bool) -> Data {
        page(Array(ids), number: number, hasMore: hasMore)
    }

    nonisolated static let errorBody = Data(#"{"status":"error","message":"nope"}"#.utf8)

    /// Serves `replies[page]` for `GET /client/favorites`, `unfavoriteStatus` for
    /// `DELETE /client/favorites/:id`, and 404 for anything else.
    nonisolated static func handler(
        _ replies: [Int: Reply],
        unfavoriteStatus: Int = 200
    ) -> @Sendable (URLRequest) throws -> (HTTPURLResponse, Data) {
        { request in
            func http(_ status: Int) -> HTTPURLResponse {
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: status,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
            }
            if request.httpMethod == "DELETE", request.url?.path.contains("/client/favorites/") == true {
                let id = request.url?.lastPathComponent ?? ""
                let body = Data(#"{"status":"success","data":{"expert_id":"\#(id)","is_favorite":false}}"#.utf8)
                return unfavoriteStatus == 200 ? (http(200), body) : (http(unfavoriteStatus), errorBody)
            }
            guard request.url?.path.hasSuffix("/client/favorites") == true, request.httpMethod == "GET" else {
                return (http(404), errorBody)
            }
            let page = queryValue("page", in: request).flatMap(Int.init) ?? 1
            switch replies[page] ?? .status(404) {
            case .page(let data): return (http(200), data)
            case .status(let code): return (http(code), errorBody)
            case .failure(let code): throw URLError(code)
            }
        }
    }

    nonisolated static func queryValue(_ name: String, in request: URLRequest) -> String? {
        request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?.first { $0.name == name }?.value
    }

    /// Every `GET /client/favorites` the stub has seen, as `(page, limit)`.
    @MainActor
    static func listRequests() -> [(page: Int, limit: Int)] {
        MockURLProtocol.recordedRequests.compactMap { request in
            guard request.url?.path.hasSuffix("/client/favorites") == true,
                  request.httpMethod == "GET",
                  let page = queryValue("page", in: request).flatMap(Int.init),
                  let limit = queryValue("limit", in: request).flatMap(Int.init)
            else { return nil }
            return (page, limit)
        }
    }
}

@Suite("Favorites paging", .serialized)
@MainActor
struct FavoritesViewModelPagingTests {

    private typealias Fixture = FavoritesFixture

    private func makeViewModel(
        _ replies: [Int: Fixture.Reply],
        unfavoriteStatus: Int = 200
    ) -> FavoritesViewModel {
        FavoritesViewModel(
            api: APITestFactory.make(respond: Fixture.handler(replies, unfavoriteStatus: unfavoriteStatus))
        )
    }

    /// Loads page 1 (20 rows, more to come) and returns the view model.
    private func loadedWithMorePages(
        second: Fixture.Reply = .page(Fixture.page(21...40, number: 2, hasMore: false)),
        unfavoriteStatus: Int = 200
    ) async -> FavoritesViewModel {
        let viewModel = makeViewModel(
            [1: .page(Fixture.page(1...20, number: 1, hasMore: true)), 2: second],
            unfavoriteStatus: unfavoriteStatus
        )
        await viewModel.load()
        return viewModel
    }

    // MARK: - Paging

    @Test("25 favorites arrive as 20 then 5: two requests with limit 20, 25 rows, no third request")
    func pagesThroughEveryFavorite() async throws {
        let viewModel = makeViewModel([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page(21...25, number: 2, hasMore: false)),
        ])

        await viewModel.load()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.favorites.count == 20)

        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.favorites[17])
        #expect(viewModel.favorites.count == 25)
        #expect(viewModel.isLoadingMore == false)

        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        let requests = Fixture.listRequests()
        #expect(requests.map(\.page) == [1, 2])
        #expect(requests.map(\.limit) == [20, 20])
    }

    @Test("a row early in the list does not start the next page")
    func earlyRowDoesNotTrigger() async {
        let viewModel = makeViewModel([1: .page(Fixture.page(1...20, number: 1, hasMore: true))])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.favorites[5])

        #expect(Fixture.listRequests().map(\.page) == [1])
        #expect(viewModel.favorites.count == 20)
    }

    @Test("exactly 20 favorites with has_more false makes one request, even after a trigger on the last row")
    func exactlyOnePageIsOneRequest() async throws {
        let viewModel = makeViewModel([1: .page(Fixture.page(1...20, number: 1, hasMore: false))])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        #expect(Fixture.listRequests().map(\.page) == [1])
        #expect(viewModel.favorites.count == 20)
    }

    @Test("an expert returned on page 1 and again on page 2 appears once")
    func adjacentPageDuplicateShownOnce() async throws {
        let viewModel = makeViewModel([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page(20...24, number: 2, hasMore: false)),
        ])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        let ids = viewModel.favorites.compactMap(\.expertId)
        #expect(ids.count == 24)
        #expect(Set(ids).count == 24)
    }

    @Test("rows keep the server order and appended pages follow page order")
    func serverOrderIsKept() async throws {
        let viewModel = makeViewModel([
            1: .page(Fixture.page([9, 4, 7], number: 1, hasMore: true)),
            2: .page(Fixture.page([2, 4, 1], number: 2, hasMore: false)),
        ])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        #expect(viewModel.favorites.map(\.name) == ["Expert 9", "Expert 4", "Expert 7", "Expert 2", "Expert 1"])
    }

    @Test("zero favorites loads an empty list and makes no second request")
    func zeroFavorites() async {
        let viewModel = makeViewModel([1: .page(Fixture.page([], number: 1, hasMore: false))])

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.favorites.isEmpty)
        #expect(Fixture.listRequests().map(\.page) == [1])
    }

    @Test("an empty later page with has_more false ends the list")
    func emptyLaterPageEnds() async throws {
        let viewModel = makeViewModel([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page([], number: 2, hasMore: false)),
        ])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        #expect(viewModel.favorites.count == 20)
        #expect(Fixture.listRequests().map(\.page) == [1, 2])
    }

    // MARK: - Later-page failure

    @Test("a failed page 2 keeps the 20 rows, shows the page error, and Retry appends the page")
    func laterPageFailureKeepsRowsAndRetryRecovers() async throws {
        let viewModel = await loadedWithMorePages(second: .failure(.networkConnectionLost))
        let before = viewModel.favorites

        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        #expect(viewModel.favorites == before)
        #expect(viewModel.hasPageError)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.state == .loaded)

        // Scrolling over the last rows again does not retry on its own.
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))
        #expect(Fixture.listRequests().map(\.page) == [1, 2])

        MockURLProtocol.handler = Fixture.handler([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page(21...25, number: 2, hasMore: false)),
        ])
        await viewModel.retryNextPage()

        #expect(viewModel.favorites.count == 25)
        #expect(viewModel.hasPageError == false)
        #expect(Fixture.listRequests().map(\.page) == [1, 2, 2])
    }

    @Test("a 500 on page 2 ends the list: rows stay, no page error, no further request")
    func serverErrorOnLaterPageIsTheEnd() async throws {
        let viewModel = await loadedWithMorePages(second: .status(500))

        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        #expect(viewModel.favorites.count == 20)
        #expect(viewModel.hasPageError == false)
        #expect(viewModel.isLoadingMore == false)
        #expect(Fixture.listRequests().map(\.page) == [1, 2])
    }

    @Test("a 500 on page 1 is a real failure and shows the first-page error")
    func serverErrorOnFirstPageIsAFailure() async {
        let viewModel = makeViewModel([1: .status(500)])

        await viewModel.load()

        guard case .failed = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
        #expect(viewModel.favorites.isEmpty)
    }

    // MARK: - Refresh

    @Test("refresh replaces the rows with a new page 1 when it succeeds")
    func refreshReplacesRows() async {
        let viewModel = await loadedWithMorePages()
        MockURLProtocol.handler = Fixture.handler([
            1: .page(Fixture.page([100, 101, 102], number: 1, hasMore: false)),
        ])

        await viewModel.refresh()

        #expect(viewModel.favorites.map(\.name) == ["Expert 100", "Expert 101", "Expert 102"])
        #expect(viewModel.apiError == nil)
        #expect(viewModel.state == .loaded)
        #expect(Fixture.listRequests().last?.page == 1)
    }

    @Test("a failed refresh keeps the rows and sets the alert text")
    func refreshFailureKeepsRows() async {
        let viewModel = await loadedWithMorePages()
        let before = viewModel.favorites
        MockURLProtocol.handler = Fixture.handler([1: .status(503)])

        await viewModel.refresh()

        #expect(viewModel.favorites == before)
        #expect(viewModel.apiError == "nope")
        #expect(viewModel.state == .loaded)
    }

    // MARK: - Unfavorite

    @Test("after a successful unfavorite with more pages, the next trigger reloads page 1, not page 2")
    func unfavoriteReloadsFromPageOne() async throws {
        let viewModel = await loadedWithMorePages()
        let removed = viewModel.favorites[3]

        await viewModel.removeFavorite(removed).value
        #expect(viewModel.favorites.count == 19)
        #expect(viewModel.favorites.contains { $0.pagingKey == removed.pagingKey } == false)

        // Page 1 now answers with the row gone and the next row moved up.
        MockURLProtocol.handler = Fixture.handler([
            1: .page(Fixture.page(Array(1...20).filter { $0 != 4 } + [21], number: 1, hasMore: true)),
            2: .page(Fixture.page(22...40, number: 2, hasMore: false)),
        ])
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        let requests = Fixture.listRequests()
        #expect(requests.last?.page == 1)
        #expect(requests.contains { $0.page == 2 } == false)
        #expect(viewModel.favorites.count == 20)
        #expect(viewModel.favorites.last?.name == "Expert 21")

        // The list is fresh again, so the following trigger pages normally.
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))
        #expect(Fixture.listRequests().last?.page == 2)
        #expect(viewModel.favorites.count == 39)
    }

    @Test("an unfavorite with every page loaded needs no reload")
    func unfavoriteWithEverythingLoaded() async throws {
        let viewModel = makeViewModel([1: .page(Fixture.page(1...5, number: 1, hasMore: false))])
        await viewModel.load()

        await viewModel.removeFavorite(viewModel.favorites[1]).value
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))

        #expect(viewModel.favorites.count == 4)
        #expect(Fixture.listRequests().map(\.page) == [1])
    }

    @Test("a failed unfavorite puts the row back at its index and does not mark the list stale")
    func failedUnfavoriteRollsBack() async throws {
        let viewModel = await loadedWithMorePages(unfavoriteStatus: 500)
        let before = viewModel.favorites

        await viewModel.removeFavorite(before[3]).value

        #expect(viewModel.favorites == before)
        #expect(viewModel.apiError != nil)
        #expect(viewModel.list.isStale == false)

        // The next trigger still asks for page 2.
        MockURLProtocol.handler = Fixture.handler([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page(21...30, number: 2, hasMore: false)),
        ])
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.favorites.last))
        #expect(Fixture.listRequests().last?.page == 2)
        #expect(viewModel.favorites.count == 30)
    }
}
