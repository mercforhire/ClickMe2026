//
//  ClientHomeFeedTests.swift
//  ClickMe2026Tests
//
//  Covers `GET /client/home` decoding through the real `NetworkService`
//  decoder, the Explore view model's price labels and failure state, and
//  the user-facing text of `NetworkError`.
//
//  Regression: `home_feed` sends `hourly_rate: {amount: 0, currency: null}`
//  for free topics created with no price. A required string currency used to
//  fail the whole decode, which took Trending Categories and Featured
//  Experts down with it.
//

import Foundation
import Testing
@testable import ClickMe2026

// MARK: - Fixtures

private enum HomeFeedFixture {
    static let expertId = "11111111-1111-4111-8111-111111111111"
    static let genericError = "Something went wrong. Please try again."

    /// One featured topic exactly as the RPC builds it. `rate` is raw JSON.
    nonisolated static func topic(
        id: String = "22222222-2222-4222-8222-222222222222",
        title: String = "Free chat",
        rate: String = #"{"amount":0,"currency":null}"#,
        isFree: Bool = true
    ) -> String {
        """
        {"topic_id":"\(id)","title":"\(title)","duration_mins":30,"hourly_rate":\(rate),\
        "is_free":\(isFree),"expert":{"expert_id":"\(expertId)","full_name":"Ada Lovelace",\
        "profile_image_url":null},"is_favorite":false,"rating":0}
        """
    }

    /// A featured topic whose `topic_id` is not a UUID, so it cannot decode.
    nonisolated static func badTopic(title: String = "Broken") -> String {
        topic(id: "not-a-uuid", title: title)
    }

    nonisolated static func recommendedExpert(id: String = expertId) -> String {
        """
        {"expert_id":"\(id)","full_name":"Ada Lovelace","title":null,"profile_image_url":null,\
        "rating":4.5,"review_count":2,"years_experience":3,"expertise_tags":["Swift"],"is_favorite":false}
        """
    }

    /// Full success envelope. Pass `featured: nil` to leave the key out.
    nonisolated static func envelope(
        featured: String?,
        experts: String? = nil
    ) -> Data {
        let featuredPart = featured.map { #","featured_topics":\#($0)"# } ?? ""
        return Data(
            """
            {"status":"success","data":{"trending_categories":[{"id":"technology","name":"Technology",\
            "icon_name":"cpu","color_accent":"#00FF00"}],"recommended_experts":[\(experts ?? recommendedExpert())]\
            \(featuredPart)}}
            """.utf8
        )
    }

    nonisolated static func envelope(topics: [String]) -> Data {
        envelope(featured: "[" + topics.joined(separator: ",") + "]")
    }

    nonisolated static func response(for request: URLRequest, status: Int = 200, body: Data) -> (HTTPURLResponse, Data) {
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (http, body)
    }
}

/// Serves `body` for `/client/home` and 404 for anything else (the view
/// model also calls `/client/bookings`, which fails silently).
@MainActor
private func makeAPI(serving body: Data) -> ClickMeAPI {
    APITestFactory.make { request in
        if request.url?.path.hasSuffix("/client/home") == true {
            return HomeFeedFixture.response(for: request, body: body)
        }
        return HomeFeedFixture.response(for: request, status: 404, body: Data(#"{"status":"error","message":"nope"}"#.utf8))
    }
}

/// Swaps the mock handler between two `load()` calls.
@MainActor
private func serve(_ body: Data) {
    MockURLProtocol.handler = { request in
        if request.url?.path.hasSuffix("/client/home") == true {
            return HomeFeedFixture.response(for: request, body: body)
        }
        return HomeFeedFixture.response(for: request, status: 404, body: Data(#"{"status":"error","message":"nope"}"#.utf8))
    }
}

@Suite("ClickMeAPI+Discovery · client home feed", .serialized)
@MainActor
struct ClientHomeFeedTests {

    // MARK: - Decoding

    @Test("decodes hourly_rate {amount:0,currency:null}")
    func decodesZeroAmountNullCurrency() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [HomeFeedFixture.topic()]))

        let response = try await api.getClientHome()

        let topic = try #require(response.data.featuredTopics?.first)
        #expect(topic.hourlyRate?.amount == 0)
        #expect(topic.hourlyRate?.currency == nil)
    }

    @Test("decodes hourly_rate null")
    func decodesNullHourlyRate() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [HomeFeedFixture.topic(rate: "null")]))

        let response = try await api.getClientHome()

        let topic = try #require(response.data.featuredTopics?.first)
        #expect(topic.hourlyRate == nil)
    }

    @Test("drops one malformed featured topic and keeps the rest of the payload")
    func dropsOnlyTheBadTopic() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [
            HomeFeedFixture.topic(title: "First"),
            HomeFeedFixture.badTopic(),
            HomeFeedFixture.topic(title: "Third"),
        ]))

        let response = try await api.getClientHome()

        #expect(response.data.featuredTopics?.map(\.title) == ["First", "Third"])
        #expect(response.data.trendingCategories.count == 1)
        #expect(response.data.recommendedExperts.count == 1)
    }

    @Test("an absent featured_topics decodes to nil")
    func absentFeaturedTopics() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(featured: nil))

        let response = try await api.getClientHome()

        #expect(response.data.featuredTopics == nil)
    }

    @Test("a null featured_topics decodes to nil")
    func nullFeaturedTopics() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(featured: "null"))

        let response = try await api.getClientHome()

        #expect(response.data.featuredTopics == nil)
    }

    @Test("a bad recommended expert still fails the decode (only featured topics are tolerant)")
    func badExpertStillThrows() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(
            featured: "[]",
            experts: HomeFeedFixture.recommendedExpert(id: "not-a-uuid")
        ))

        await #expect {
            try await api.getClientHome()
        } throws: { error in
            if case NetworkError.decodingFailed = error { return true }
            return false
        }
    }

    // MARK: - Price labels

    @Test(
        "a free topic shows Free whatever the rate holds",
        arguments: [
            #"{"amount":0,"currency":null}"#,
            "null",
            #"{"amount":0,"currency":"CAD"}"#,
        ]
    )
    func freeTopicShowsFree(rate: String) async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [
            HomeFeedFixture.topic(rate: rate, isFree: true),
        ]))
        let viewModel = ExploreClientViewModel(api: api)

        await viewModel.load()

        #expect(viewModel.featuredTopics.map(\.priceLabel) == ["Free"])
    }

    @Test("a paid USD topic shows a formatted price")
    func paidTopicShowsPrice() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [
            HomeFeedFixture.topic(rate: #"{"amount":5000,"currency":"USD"}"#, isFree: false),
        ]))
        let viewModel = ExploreClientViewModel(api: api)

        await viewModel.load()

        let label = try #require(viewModel.featuredTopics.first?.priceLabel)
        // The test plan runs en_GB, so the symbol varies. Only the amount is stable.
        #expect(label != "Free")
        #expect(label != "—")
        #expect(label.contains("50"))
    }

    @Test("a paid topic with no currency shows a dash")
    func paidTopicWithoutCurrencyShowsDash() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [
            HomeFeedFixture.topic(rate: #"{"amount":5000,"currency":null}"#, isFree: false),
        ]))
        let viewModel = ExploreClientViewModel(api: api)

        await viewModel.load()

        #expect(viewModel.featuredTopics.map(\.priceLabel) == ["—"])
    }

    @Test("a paid topic with a null rate shows a dash")
    func paidTopicWithNullRateShowsDash() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [
            HomeFeedFixture.topic(rate: "null", isFree: false),
        ]))
        let viewModel = ExploreClientViewModel(api: api)

        await viewModel.load()

        #expect(viewModel.featuredTopics.map(\.priceLabel) == ["—"])
    }

    // MARK: - Screen state

    @Test("a mixed array leaves all three sections loaded")
    func mixedArrayLoadsEverySection() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [
            HomeFeedFixture.topic(title: "First"),
            HomeFeedFixture.badTopic(),
            HomeFeedFixture.topic(title: "Third"),
        ]))
        let viewModel = ExploreClientViewModel(api: api)

        await viewModel.load()

        #expect(viewModel.categoriesState == .loaded)
        #expect(viewModel.expertsState == .loaded)
        #expect(viewModel.featuredTopicsState == .loaded)
        #expect(viewModel.featuredTopics.map(\.title) == ["First", "Third"])
        #expect(viewModel.categories.count == 1)
        #expect(viewModel.experts.count == 1)
    }

    @Test("an array where every topic is bad gives an empty, loaded section")
    func allBadTopicsGiveEmptyLoadedSection() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [
            HomeFeedFixture.badTopic(title: "A"),
            HomeFeedFixture.badTopic(title: "B"),
        ]))
        let viewModel = ExploreClientViewModel(api: api)

        await viewModel.load()

        #expect(viewModel.featuredTopics.isEmpty)
        #expect(viewModel.featuredTopicsState == .loaded)
        #expect(viewModel.categoriesState == .loaded)
        #expect(viewModel.expertsState == .loaded)
    }

    @Test("a failed reload clears stale featured topics and shows readable text")
    func failedReloadClearsFeaturedTopics() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [HomeFeedFixture.topic()]))
        let viewModel = ExploreClientViewModel(api: api)
        await viewModel.load()
        #expect(viewModel.featuredTopics.count == 1)

        // A recommended expert with a bad id fails the whole decode.
        serve(HomeFeedFixture.envelope(
            featured: "[]",
            experts: HomeFeedFixture.recommendedExpert(id: "not-a-uuid")
        ))
        await viewModel.reload()

        let failed = LoadState.failed(HomeFeedFixture.genericError)
        #expect(viewModel.featuredTopics.isEmpty)
        #expect(viewModel.categoriesState == failed)
        #expect(viewModel.expertsState == failed)
        #expect(viewModel.featuredTopicsState == failed)
    }

    @Test("a cancelled reload keeps the featured topics and sets no failure")
    func cancelledReloadKeepsFeaturedTopics() async throws {
        let api = makeAPI(serving: HomeFeedFixture.envelope(topics: [HomeFeedFixture.topic()]))
        let viewModel = ExploreClientViewModel(api: api)
        await viewModel.load()
        #expect(viewModel.featuredTopics.count == 1)

        MockURLProtocol.handler = { _ in throw URLError(.cancelled) }
        await viewModel.reload()

        #expect(viewModel.featuredTopics.count == 1)
        for state in [viewModel.categoriesState, viewModel.expertsState, viewModel.featuredTopicsState] {
            if case .failed = state {
                Issue.record("a cancelled reload must not set a failed state")
            }
        }
    }

    // MARK: - Error text

    private static let everyNetworkError: [NetworkError] = [
        .invalidURL,
        .invalidResponse,
        .httpError(statusCode: 500, data: Data("<html>oops</html>".utf8)),
        .decodingFailed(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "secret-internals"))),
        .encodingFailed(URLError(.badURL)),
        .invalidDate,
    ]

    @Test("no NetworkError case leaks its type name into user-facing text")
    func networkErrorTextIsReadable() {
        for error in Self.everyNetworkError {
            #expect(!error.userMessage.contains("NetworkError"), "userMessage for \(error)")
            #expect(!error.localizedDescription.contains("NetworkError"), "localizedDescription for \(error)")
        }
    }

    @Test("a decoding failure shows generic text, not decoder details")
    func decodingFailureHidesInternals() {
        let error = NetworkError.decodingFailed(
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "secret-internals"))
        )

        #expect(!error.userMessage.contains("secret-internals"))
        #expect(!error.localizedDescription.contains("secret-internals"))
        #expect(error.userMessage == HomeFeedFixture.genericError)
    }

    @Test("an HTTP error with a StandardErrorResponse body keeps the server message")
    func httpErrorKeepsServerMessage() {
        let body = Data(#"{"status":"error","code":"BOOKING_ATTEMPT_CONFLICT","message":"Server says no"}"#.utf8)
        let error = NetworkError.httpError(statusCode: 409, data: body)

        #expect(error.userMessage == "Server says no")
    }

    @Test("an HTTP error with an undecodable body shows generic text")
    func httpErrorWithUndecodableBodyIsGeneric() {
        let error = NetworkError.httpError(statusCode: 502, data: Data("<html>bad gateway</html>".utf8))

        #expect(error.userMessage == HomeFeedFixture.genericError)
    }
}
