//
//  ExpertProfileViewModelTests.swift
//  ClickMe2026Tests
//
//  Covers the Expert Profile load states (EXPL-01, D-10): a 404 from
//  `GET /experts/:id/details` is "not available" with no retry, any other
//  failure is "couldn't load" with a working Retry, and a loaded profile
//  merges the server fields.
//

import Foundation
import Testing
@testable import ClickMe2026

// MARK: - Fixtures

private enum ProfileFixture {
    static let expertId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    static let serverName = "Ada Lovelace"

    /// `GET /experts/:id/details` success body. `isFavorite` is raw JSON, or
    /// nil to leave the key out.
    nonisolated static func details(isFavorite: String? = nil) -> Data {
        let favoritePart = isFavorite.map { #","is_favorite":\#($0)"# } ?? ""
        return Data(
            """
            {"status":"success","data":{"profile":{"name":"\(serverName)","title":"Mathematician",\
            "bio":"Wrote the first program.","stats":{"experience_years":5,"total_bookings":3}},\
            "topics_of_discussion":[],"recent_reviews":[],"is_bookable":true\(favoritePart)}}
            """.utf8
        )
    }

    /// `GET /experts/:id/reviews` success body with an empty page.
    nonisolated static let reviews = Data(
        """
        {"status":"success","data":{"summary":{"expert_id":"11111111-1111-4111-8111-111111111111",\
        "overall_rating":4.5,"total_reviews":2,"rating_distribution":{"5_star":1,"4_star":1,\
        "3_star":0,"2_star":0,"1_star":0}},"reviews":[]}}
        """.utf8
    )

    nonisolated static let favoritesEmpty = Data(
        #"{"status":"success","data":{"experts":[],"pagination":{"page":1,"limit":100,"total":0,"has_more":false}}}"#.utf8
    )

    nonisolated static let notFoundBody = Data(
        #"{"status":"error","code":"NOT_FOUND","message":"Expert not found"}"#.utf8
    )

    nonisolated static let serverErrorBody = Data(
        #"{"status":"error","message":"Server exploded"}"#.utf8
    )

    nonisolated static func response(
        for request: URLRequest,
        status: Int = 200,
        body: Data
    ) -> (HTTPURLResponse, Data) {
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (http, body)
    }

    /// A caller-seeded profile, as the Explore / Search / Favorites cards build it.
    static func seed() -> PublicExpertProfile {
        PublicExpertProfile(
            expertId: expertId,
            name: "Seed Name",
            title: "",
            rating: 0,
            reviewCount: 0,
            yearsExp: "",
            bookings: "",
            isOnline: false,
            bio: "",
            expertiseTags: [],
            topics: [],
            reviews: [],
            imageURL: ""
        )
    }
}

/// Routes by path: `/details` answers with `detailsStatus` and `detailsBody`
/// (or throws `detailsError`), `/reviews` and `/client/favorites` succeed.
private func route(
    detailsStatus: Int = 200,
    detailsBody: Data = ProfileFixture.details(),
    detailsError: URLError? = nil
) -> @Sendable (URLRequest) throws -> (HTTPURLResponse, Data) {
    { request in
        let path = request.url?.path ?? ""
        if path.hasSuffix("/details") {
            if let detailsError { throw detailsError }
            return ProfileFixture.response(for: request, status: detailsStatus, body: detailsBody)
        }
        if path.hasSuffix("/reviews") {
            return ProfileFixture.response(for: request, body: ProfileFixture.reviews)
        }
        if path.hasSuffix("/client/favorites") {
            return ProfileFixture.response(for: request, body: ProfileFixture.favoritesEmpty)
        }
        return ProfileFixture.response(for: request, status: 404, body: ProfileFixture.notFoundBody)
    }
}

@MainActor
private func makeViewModel(
    handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
) -> ExpertProfileViewModel {
    let api = APITestFactory.make(respond: handler)
    return ExpertProfileViewModel(expert: ProfileFixture.seed(), api: api)
}

private func requestCount(pathSuffix: String) -> Int {
    MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix(pathSuffix) == true }.count
}

// MARK: - Suite

@Suite("Expert profile view model", .serialized)
@MainActor
struct ExpertProfileViewModelTests {

    // MARK: Load states

    @Test("details 404 with NOT_FOUND is notFound and makes no reviews request")
    func notFoundByCode() async {
        let viewModel = makeViewModel(
            handler: route(detailsStatus: 404, detailsBody: ProfileFixture.notFoundBody)
        )

        await viewModel.loadProfileDetails()

        #expect(viewModel.loadState == .notFound)
        #expect(requestCount(pathSuffix: "/reviews") == 0)
    }

    @Test("details 404 with an unreadable body is still notFound (status code, not message text)")
    func notFoundByStatus() async {
        let viewModel = makeViewModel(
            handler: route(detailsStatus: 404, detailsBody: Data("not json".utf8))
        )

        await viewModel.loadProfileDetails()

        #expect(viewModel.loadState == .notFound)
    }

    @Test("a transport failure is failed with a message")
    func networkFailure() async {
        let viewModel = makeViewModel(
            handler: route(detailsError: URLError(.notConnectedToInternet))
        )

        await viewModel.loadProfileDetails()

        guard case let .failed(message) = viewModel.loadState else {
            Issue.record("expected .failed, got \(viewModel.loadState)")
            return
        }
        #expect(!message.isEmpty)
        #expect(requestCount(pathSuffix: "/reviews") == 0)
    }

    @Test("a 500 is failed with the server message, not notFound")
    func serverError() async {
        let viewModel = makeViewModel(
            handler: route(detailsStatus: 500, detailsBody: ProfileFixture.serverErrorBody)
        )

        await viewModel.loadProfileDetails()

        #expect(viewModel.loadState == .failed("Server exploded"))
    }

    @Test("a 200 details load is loaded and merges the server fields")
    func loadedMerge() async {
        let viewModel = makeViewModel(handler: route())

        #expect(viewModel.loadState == .loading)
        await viewModel.loadProfileDetails()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.expert.name == ProfileFixture.serverName)
        #expect(viewModel.expert.reviewCount == 2)
        #expect(viewModel.isSummaryLoaded)
    }

    // MARK: Retry

    @Test("retry after a failure with a 200 stub loads the profile")
    func retrySucceeds() async {
        let viewModel = makeViewModel(
            handler: route(detailsError: URLError(.notConnectedToInternet))
        )
        await viewModel.loadProfileDetails()

        MockURLProtocol.handler = route()
        await viewModel.retry()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.expert.name == ProfileFixture.serverName)
        #expect(!viewModel.isRetrying)
    }

    @Test("retry after a failure that now returns 404 switches to notFound")
    func retryFindsNotFound() async {
        let viewModel = makeViewModel(
            handler: route(detailsError: URLError(.notConnectedToInternet))
        )
        await viewModel.loadProfileDetails()

        MockURLProtocol.handler = route(detailsStatus: 404, detailsBody: ProfileFixture.notFoundBody)
        await viewModel.retry()

        #expect(viewModel.loadState == .notFound)
        #expect(!viewModel.isRetrying)
    }

    @Test("two retries started back to back make one details request")
    func doubleRetryIsOneRequest() async {
        let viewModel = makeViewModel(
            handler: route(detailsError: URLError(.notConnectedToInternet))
        )
        await viewModel.loadProfileDetails()

        MockURLProtocol.recordedRequests = []
        MockURLProtocol.handler = route()
        let first = Task { await viewModel.retry() }
        let second = Task { await viewModel.retry() }
        await first.value
        await second.value

        #expect(requestCount(pathSuffix: "/details") == 1)
        #expect(!viewModel.isRetrying)
        #expect(viewModel.loadState == .loaded)
    }
}
