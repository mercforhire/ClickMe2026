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

    // MARK: - Free topic stored with no currency (G-06-1-currency)

    /// The wire shape the backend sends for a free topic stored with no
    /// currency: `price.currency` is `""` and there is no `hourly_rate` key.
    nonisolated private static let blankCurrencyFreeTopicJSON = """
    {
      "id": "\(topicId)",
      "title": "Intro chat",
      "duration_mins": 30,
      "description": null,
      "icon_slug": null,
      "price": { "amount": 0, "currency": "", "is_free": true, "label": "Free" }
    }
    """

    @Test("G-06-1-currency: a free topic stored with no currency opens on the default and saves a 3-letter code")
    func blankCurrencyFreeTopicSavesARealCurrency() async throws {
        let stored = try Self.decodeTopic(Self.blankCurrencyFreeTopicJSON)
        #expect(stored.storedCurrency == nil)

        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: Self.topicEnvelope(Self.blankCurrencyFreeTopicJSON))
        }
        // The account is injected so the result does not depend on the shared
        // user manager (06-REVIEW IN-07). USD, not CAD, so a hidden CAD fallback fails.
        let me = try MeDataFixtures.me(defaultCurrency: "USD", allowedCurrencies: ["CAD", "USD"])
        let editor = TopicEditorViewModel(topic: stored, api: api, meProvider: { me })
        #expect(editor.currency == "USD")
        #expect(editor.defaultCurrency == "USD")
        #expect(editor.isCurrencyLocked == false)
        #expect(editor.pickableCurrencies.contains("") == false)
        #expect(editor.pickableCurrencies == ["CAD", "USD"])

        let validated = try #require(editor.validate())
        #expect(validated.currency == "USD")

        let viewModel = TopicsSetupViewModel(api: api)
        viewModel.topics = [stored]
        viewModel.editTopic(stored)
        let error = await viewModel.saveTopic(
            title: validated.title,
            description: validated.description,
            durationMins: validated.durationMinutes,
            hourlyRateAmount: validated.hourlyRateAmount,
            currency: validated.currency,
            iconSlug: validated.iconSlug,
            expertiseTagIds: validated.expertiseTagIds
        )

        #expect(error == nil)
        let sent = Self.patches()
        #expect(sent.count == 1)
        let body = try #require(sent.first?.jsonBodyForTest())
        let rate = try #require(body["hourly_rate"] as? [String: Any])
        let currency = try #require(rate["currency"] as? String)
        #expect(currency == "USD")
        #expect(currency.count == 3)
        #expect(body["is_free"] as? Bool == true)
    }

    // MARK: - Delete confirmation (EXP-01, D-14) and removal after 2xx (EXP-08)

    nonisolated private static func deletes() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { $0.httpMethod == "DELETE" }
    }

    private func makeViewModel(
        deleteStatus: Int = 200,
        deleteBody: Data = ClientBookingFixtures.successMessage
    ) throws -> (TopicsSetupViewModel, ExpertTopicItem, ExpertTopicItem) {
        let first = try Self.decodeTopic(Self.topicJSON())
        let second = try Self.decodeTopic(Self.topicJSON(id: Self.otherTopicId, title: "Intro chat"))
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, status: deleteStatus, body: deleteBody)
        }
        let viewModel = TopicsSetupViewModel(api: api)
        viewModel.topics = [first, second]
        return (viewModel, first, second)
    }

    @Test("tapping Delete only asks: the topic is pending and no request is sent")
    func requestDeleteSendsNothing() throws {
        let (viewModel, first, _) = try makeViewModel()

        viewModel.requestDelete(first)

        #expect(viewModel.topicPendingDelete?.id == first.id)
        #expect(Self.deletes().isEmpty)
        #expect(viewModel.topics.count == 2)
    }

    @Test("Cancel clears the pending topic, sends nothing and keeps the card")
    func cancelDeleteSendsNothing() throws {
        let (viewModel, first, _) = try makeViewModel()
        viewModel.requestDelete(first)

        viewModel.cancelDelete()

        #expect(viewModel.topicPendingDelete == nil)
        #expect(Self.deletes().isEmpty)
        #expect(viewModel.topics.map(\.id) == [first.id, UUID(uuidString: Self.otherTopicId)!])
    }

    @Test("confirming sends one DELETE for that topic and removes it after the 2xx")
    func confirmDeleteRemovesAfterSuccess() async throws {
        let (viewModel, first, second) = try makeViewModel()
        viewModel.requestDelete(first)

        await viewModel.confirmDelete(first)

        #expect(viewModel.topicPendingDelete == nil)
        let sent = Self.deletes()
        #expect(sent.count == 1)
        #expect(sent.first?.url?.path.hasSuffix("/expert/topics/\(first.id.uuidString.lowercased())") == true)
        #expect(viewModel.topics.map(\.id) == [second.id])
        #expect(viewModel.apiError == nil)
    }

    @Test("a failed DELETE keeps the card and shows the server message")
    func failedDeleteKeepsTheTopic() async throws {
        let (viewModel, first, second) = try makeViewModel(
            deleteStatus: 404,
            deleteBody: Fixtures.errorBody(code: "NOT_FOUND", message: "Topic not found")
        )
        viewModel.requestDelete(first)

        await viewModel.confirmDelete(first)

        #expect(viewModel.topicPendingDelete == nil)
        #expect(viewModel.apiError == "Topic not found")
        #expect(viewModel.topics.map(\.id) == [first.id, second.id])
    }

    @Test("a repeat DELETE of a topic already removed answers 404 and leaves the list as it was")
    func secondDeleteLeavesTheListAlone() async throws {
        let (viewModel, first, second) = try makeViewModel()
        await viewModel.confirmDelete(first)
        #expect(viewModel.topics.map(\.id) == [second.id])

        // The server now answers the same id with a 404.
        let api = APITestFactory.make { request in
            Fixtures.response(
                for: request,
                status: 404,
                body: Fixtures.errorBody(code: "NOT_FOUND", message: "Topic not found")
            )
        }
        let again = TopicsSetupViewModel(api: api)
        again.topics = [second]
        await again.confirmDelete(first)

        #expect(again.apiError == "Topic not found")
        #expect(again.topics.map(\.id) == [second.id])
        #expect(Self.deletes().count == 1)
    }
}
