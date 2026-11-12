//
//  ExpertReviewsViewModelPagingTests.swift
//  ClickMe2026Tests
//
//  EXPL-06 / D-07: the full reviews list loads `GET /experts/:id/reviews` in
//  pages of 20, fetches the next page when one of the last 3 rows appears,
//  stops on `has_more` false, and never shows the same review twice. The
//  header numbers come from `summary`, because the pagination envelope has no
//  total.
//

import Foundation
import Testing
@testable import ClickMe2026

// MARK: - Fixtures

private enum ReviewsFixture {

    /// What the stubbed server answers for one `page` value.
    enum Reply: Sendable {
        case page(Data)
        case status(Int)
        case failure(URLError.Code)
    }

    static let expertId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!

    nonisolated static func reviewId(_ n: Int) -> String {
        "00000000-0000-4000-8000-" + String(format: "%012d", n)
    }

    nonisolated static func item(_ n: Int) -> String {
        """
        {"id":"\(reviewId(n))","reviewer":{"name":"Reviewer \(n)","avatar_url":null},\
        "session_context":{"topic":"Topic","date":null,"date_label":null},\
        "rating":5,"comment":"Comment \(n)","created_at":"2026-01-01T00:00:00.000Z","verified_booking":true}
        """
    }

    /// One success envelope holding reviews `ids` as page `number`. The summary
    /// always claims 128 reviews at 4.8, whatever the page holds.
    nonisolated static func page(_ ids: [Int], number: Int, hasMore: Bool, totalPages: Int = 2) -> Data {
        Data(
            """
            {"status":"success","data":{"summary":{"expert_id":"\(expertId.uuidString)",\
            "overall_rating":4.8,"total_reviews":128,\
            "rating_distribution":{"5_star":100,"4_star":20,"3_star":5,"2_star":2,"1_star":1}},\
            "reviews":[\(ids.map(item).joined(separator: ","))],\
            "pagination":{"current_page":\(number),"total_pages":\(totalPages),"has_more":\(hasMore)}}}
            """.utf8
        )
    }

    nonisolated static func page(_ ids: ClosedRange<Int>, number: Int, hasMore: Bool) -> Data {
        page(Array(ids), number: number, hasMore: hasMore)
    }

    nonisolated static let errorBody = Data(#"{"status":"error","message":"nope"}"#.utf8)

    /// Serves `replies[page]` for `GET /experts/:id/reviews`, and 404 for anything else.
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
            guard request.url?.path.hasSuffix("/reviews") == true, request.httpMethod == "GET" else {
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

    /// Every `GET .../reviews` the stub has seen, as `(page, limit)`.
    @MainActor
    static func listRequests() -> [(page: Int, limit: Int)] {
        MockURLProtocol.recordedRequests.compactMap { request in
            guard request.url?.path.hasSuffix("/reviews") == true,
                  request.httpMethod == "GET",
                  let page = queryValue("page", in: request).flatMap(Int.init),
                  let limit = queryValue("limit", in: request).flatMap(Int.init)
            else { return nil }
            return (page, limit)
        }
    }
}

@Suite("Expert reviews paging", .serialized)
@MainActor
struct ExpertReviewsViewModelPagingTests {

    private typealias Fixture = ReviewsFixture

    private func makeViewModel(_ replies: [Int: Fixture.Reply]) -> ExpertReviewsViewModel {
        ExpertReviewsViewModel(
            expertId: Fixture.expertId,
            expertName: "Sophia Carter",
            api: APITestFactory.make(respond: Fixture.handler(replies))
        )
    }

    /// Loads page 1 (20 reviews, more to come) and returns the view model.
    private func loadedWithMorePages(
        second: Fixture.Reply = .page(Fixture.page(21...40, number: 2, hasMore: false))
    ) async -> ExpertReviewsViewModel {
        let viewModel = makeViewModel([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: second,
        ])
        await viewModel.load()
        return viewModel
    }

    // MARK: - Paging

    @Test("25 reviews arrive as 20 then 5: two requests with limit 20, 25 reviews, no third request")
    func pagesThroughEveryReview() async throws {
        let viewModel = makeViewModel([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page(21...25, number: 2, hasMore: false)),
        ])

        await viewModel.load()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.reviews.count == 20)

        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.reviews[17])
        #expect(viewModel.reviews.count == 25)
        #expect(viewModel.isLoadingMore == false)

        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))

        let requests = Fixture.listRequests()
        #expect(requests.map(\.page) == [1, 2])
        #expect(requests.map(\.limit) == [20, 20])
    }

    @Test("a review early in the list does not start the next page")
    func earlyRowDoesNotTrigger() async {
        let viewModel = makeViewModel([1: .page(Fixture.page(1...20, number: 1, hasMore: true))])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.reviews[5])

        #expect(Fixture.listRequests().map(\.page) == [1])
        #expect(viewModel.reviews.count == 20)
    }

    @Test("exactly 20 reviews with has_more false makes one request, even after a trigger on the last row")
    func exactlyOnePageIsOneRequest() async throws {
        let viewModel = makeViewModel([1: .page(Fixture.page(1...20, number: 1, hasMore: false))])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))

        #expect(Fixture.listRequests().map(\.page) == [1])
        #expect(viewModel.reviews.count == 20)
    }

    @Test("a review returned on page 1 and again on page 2 appears once, in its page-1 position")
    func adjacentPageDuplicateShownOnce() async throws {
        let viewModel = makeViewModel([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page(20...24, number: 2, hasMore: false)),
        ])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))

        let ids = viewModel.reviews.compactMap(\.serverId)
        #expect(ids.count == 24)
        #expect(Set(ids).count == 24)
        #expect(viewModel.reviews.firstIndex { $0.reviewerName == "Reviewer 20" } == 19)
    }

    @Test("reviews keep the server order and appended pages follow page order")
    func serverOrderIsKept() async throws {
        let viewModel = makeViewModel([
            1: .page(Fixture.page([9, 4, 7], number: 1, hasMore: true)),
            2: .page(Fixture.page([2, 4, 1], number: 2, hasMore: false)),
        ])

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))

        #expect(
            viewModel.reviews.map(\.reviewerName)
                == ["Reviewer 9", "Reviewer 4", "Reviewer 7", "Reviewer 2", "Reviewer 1"]
        )
    }

    @Test("zero reviews loads an empty list and makes no second request")
    func zeroReviews() async {
        let viewModel = makeViewModel([1: .page(Fixture.page([], number: 1, hasMore: false))])

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.reviews.isEmpty)
        #expect(Fixture.listRequests().map(\.page) == [1])
    }

    @Test("the header rating and count come from summary, not from the loaded rows")
    func headerComesFromSummary() async {
        let viewModel = await loadedWithMorePages()

        #expect(viewModel.reviews.count == 20)
        #expect(viewModel.totalReviews == 128)
        #expect(viewModel.overallRating == 4.8)
    }

    // MARK: - Later-page failure

    @Test("a failed page 2 keeps the 20 reviews, shows the page error, and Retry appends the page")
    func laterPageFailureKeepsRowsAndRetryRecovers() async throws {
        let viewModel = await loadedWithMorePages(second: .failure(.networkConnectionLost))
        let before = viewModel.reviews.map(\.pagingKey)

        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))

        #expect(viewModel.reviews.map(\.pagingKey) == before)
        #expect(viewModel.hasPageError)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.state == .loaded)

        // Scrolling over the last rows again does not retry on its own.
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))
        #expect(Fixture.listRequests().map(\.page) == [1, 2])

        MockURLProtocol.handler = Fixture.handler([
            1: .page(Fixture.page(1...20, number: 1, hasMore: true)),
            2: .page(Fixture.page(21...25, number: 2, hasMore: false)),
        ])
        await viewModel.retryNextPage()

        #expect(viewModel.reviews.count == 25)
        #expect(viewModel.hasPageError == false)
        #expect(Fixture.listRequests().map(\.page) == [1, 2, 2])
    }

    @Test("a 500 on page 2 ends the list: reviews stay, no page error, no further request")
    func serverErrorOnLaterPageIsTheEnd() async throws {
        let viewModel = await loadedWithMorePages(second: .status(500))

        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))
        await viewModel.loadNextPageIfNeeded(currentItem: try #require(viewModel.reviews.last))

        #expect(viewModel.reviews.count == 20)
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
        #expect(viewModel.reviews.isEmpty)
    }

    // MARK: - Refresh

    @Test("refresh replaces the reviews with a new page 1 when it succeeds")
    func refreshReplacesRows() async {
        let viewModel = await loadedWithMorePages()
        MockURLProtocol.handler = Fixture.handler([
            1: .page(Fixture.page([100, 101, 102], number: 1, hasMore: false)),
        ])

        await viewModel.refresh()

        #expect(viewModel.reviews.map(\.reviewerName) == ["Reviewer 100", "Reviewer 101", "Reviewer 102"])
        #expect(viewModel.state == .loaded)
        #expect(Fixture.listRequests().last?.page == 1)
    }

    @Test("a failed refresh keeps the reviews")
    func refreshFailureKeepsRows() async {
        let viewModel = await loadedWithMorePages()
        let before = viewModel.reviews.map(\.pagingKey)
        MockURLProtocol.handler = Fixture.handler([1: .status(503)])

        await viewModel.refresh()

        #expect(viewModel.reviews.map(\.pagingKey) == before)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.hasPageError == false)
    }
}
