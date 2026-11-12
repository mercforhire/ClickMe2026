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

    /// Serves `replies[page]` for `GET /client/favorites` and 404 for anything else.
    nonisolated static func handler(
        _ replies: [Int: Reply]
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

    private func makeViewModel(_ replies: [Int: Fixture.Reply]) -> FavoritesViewModel {
        FavoritesViewModel(api: APITestFactory.make(respond: Fixture.handler(replies)))
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
}
