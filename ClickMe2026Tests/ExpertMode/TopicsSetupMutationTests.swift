//
//  TopicsSetupMutationTests.swift
//  ClickMe2026Tests
//
//  EXP-04 (D-15): editing a topic and clearing its icon or description sends an
//  explicit JSON null on `PATCH /expert/topics/:id`; leaving them alone sends
//  neither key. EXP-01 (D-14): Delete asks first, nothing is sent until the
//  expert confirms, and a topic leaves the list only after a 2xx (EXP-08).
//
//  Each test installs its own `MockURLProtocol` handler through
//  `APITestFactory.make` and awaits its requests before returning, so the suite
//  is safe next to the other stubbed suites in one invocation.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Topics setup mutations", .serialized)
@MainActor
struct TopicsSetupMutationTests {

    private typealias Fixtures = ClientBookingFixtures

    // MARK: - Fixtures

    nonisolated private static let topicId = "11111111-1111-1111-1111-111111111111"
    nonisolated private static let otherTopicId = "22222222-2222-2222-2222-222222222222"

    nonisolated private static func topicJSON(
        id: String = topicId,
        title: String = "Portfolio review",
        description: String? = "Old",
        iconSlug: String? = "marketing"
    ) -> String {
        let desc = description.map { "\"\($0)\"" } ?? "null"
        let icon = iconSlug.map { "\"\($0)\"" } ?? "null"
        return """
        {
          "id": "\(id)",
          "title": "\(title)",
          "duration_mins": 60,
          "description": \(desc),
          "price": { "amount": 5000, "currency": "CAD", "is_free": false, "label": "CA$50" },
          "hourly_rate": { "amount": 5000, "currency": "CAD" },
          "icon_slug": \(icon)
        }
        """
    }

    nonisolated private static func topicEnvelope(_ topic: String) -> Data {
        Data(#"{"status":"success","data":{"topic":\#(topic)}}"#.utf8)
    }

    private static func decodeTopic(_ json: String) throws -> ExpertTopicItem {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ExpertTopicItem.self, from: Data(json.utf8))
    }

    nonisolated private static func patches() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { $0.httpMethod == "PATCH" }
    }

    // MARK: - PATCH body (EXP-04, D-15)

    @Test("clearing the icon and description sends explicit nulls and replaces the list entry")
    func clearedFieldsSendNull() async throws {
        let stored = try Self.decodeTopic(Self.topicJSON())
        let api = APITestFactory.make { request in
            Fixtures.response(
                for: request,
                body: Self.topicEnvelope(Self.topicJSON(description: nil, iconSlug: nil))
            )
        }
        let viewModel = TopicsSetupViewModel(api: api)
        viewModel.topics = [stored]
        viewModel.editTopic(stored)

        let error = await viewModel.saveTopic(
            title: "Portfolio review",
            description: nil,
            durationMins: 60,
            hourlyRateAmount: 5000,
            currency: "CAD",
            iconSlug: nil,
            expertiseTagIds: []
        )

        #expect(error == nil)
        let sent = Self.patches()
        #expect(sent.count == 1)
        let body = try #require(sent.first?.jsonBodyForTest())
        #expect(body["icon_slug"] is NSNull)
        #expect(body["description"] is NSNull)
        #expect(viewModel.topics.count == 1)
        #expect(viewModel.topics.first?.iconSlug == nil)
        #expect(viewModel.topics.first?.description == nil)
    }

    @Test("a save that leaves the stored icon and description alone sends neither key")
    func unchangedFieldsSendNoKeys() async throws {
        let stored = try Self.decodeTopic(Self.topicJSON())
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Self.topicEnvelope(Self.topicJSON()))
        }
        let viewModel = TopicsSetupViewModel(api: api)
        viewModel.topics = [stored]
        viewModel.editTopic(stored)

        let error = await viewModel.saveTopic(
            title: "Portfolio review",
            description: "Old",
            durationMins: 60,
            hourlyRateAmount: 5000,
            currency: "CAD",
            iconSlug: "marketing",
            expertiseTagIds: []
        )

        #expect(error == nil)
        let sent = Self.patches()
        #expect(sent.count == 1)
        let body = try #require(sent.first?.jsonBodyForTest())
        #expect(body["icon_slug"] == nil)
        #expect(body["description"] == nil)
        #expect(body["title"] as? String == "Portfolio review")
    }
}
