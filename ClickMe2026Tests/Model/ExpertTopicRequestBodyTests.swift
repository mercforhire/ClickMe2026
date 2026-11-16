//
//  ExpertTopicRequestBodyTests.swift
//  ClickMe2026Tests
//
//  EXP-04 / D-15: the `PATCH /expert/topics/:id` body can clear a topic's icon
//  or description. A cleared stored value goes out as JSON null, an unchanged
//  one is omitted, and a changed one is sent. Every other key encodes as it did
//  before the three-state field existed.
//
//  Pure: the encoder uses the same `.convertToSnakeCase` strategy as
//  `NetworkService`, and no row touches the network or `UserManager.shared`.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Expert topic PATCH body")
struct ExpertTopicRequestBodyTests {

    // MARK: - NullableField.patch

    @Test("an unchanged stored value is omitted")
    func unchangedIsOmitted() {
        #expect(NullableField<String>.patch(old: "Old", new: "Old") == .omit)
    }

    @Test("a cleared stored value is null")
    func clearedStoredValueIsNull() {
        #expect(NullableField<String>.patch(old: "Old", new: nil) == .null)
    }

    @Test("a value set where none was stored is sent")
    func setFromNothingIsSet() {
        #expect(NullableField<String>.patch(old: nil, new: "New") == .set("New"))
    }

    @Test("nothing stored and nothing typed is omitted, never null")
    func nothingToNothingIsOmitted() {
        #expect(NullableField<String>.patch(old: nil, new: nil) == .omit)
    }

    @Test("a changed value is sent")
    func changedIsSet() {
        #expect(NullableField<String>.patch(old: "Old", new: "New") == .set("New"))
    }

    // MARK: - Encoding

    private static func json(
        description: NullableField<String> = .omit,
        iconSlug: NullableField<String> = .omit,
        title: String? = nil,
        durationMins: Int? = nil,
        hourlyRate: UpdateExpertTopicRequest.HourlyRate? = nil,
        isFree: Bool? = nil,
        expertiseTagIds: [String]? = nil
    ) throws -> [String: Any] {
        let body = UpdateExpertTopicRequest(
            title: title,
            description: description,
            durationMins: durationMins,
            hourlyRate: hourlyRate,
            isFree: isFree,
            iconSlug: iconSlug,
            expertiseTagIds: expertiseTagIds
        )
        // Same key strategy as NetworkService.
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try #require(
            try JSONSerialization.jsonObject(with: encoder.encode(body)) as? [String: Any]
        )
    }

    @Test("null fields encode as JSON null under icon_slug and description")
    func nullEncodesAsNSNull() throws {
        let json = try Self.json(description: .null, iconSlug: .null)

        #expect(json["description"] is NSNull)
        #expect(json["icon_slug"] is NSNull)
        #expect(Set(json.keys) == ["description", "icon_slug"])
    }

    @Test("omitted fields leave both keys out")
    func omitLeavesKeysOut() throws {
        let json = try Self.json(description: .omit, iconSlug: .omit, title: "Review")

        #expect(json["description"] == nil)
        #expect(json["icon_slug"] == nil)
        #expect(Set(json.keys) == ["title"])
    }

    @Test("set fields encode the string")
    func setEncodesTheString() throws {
        let json = try Self.json(description: .set("x"), iconSlug: .set("marketing"))

        #expect(json["description"] as? String == "x")
        #expect(json["icon_slug"] as? String == "marketing")
    }

    @Test("the other five keys encode as before")
    func otherKeysUnchanged() throws {
        let json = try Self.json(
            title: "Portfolio review",
            durationMins: 60,
            hourlyRate: .init(amount: 5000, currency: "CAD"),
            isFree: false,
            expertiseTagIds: ["tag-1", "tag-2"]
        )

        #expect(json["title"] as? String == "Portfolio review")
        #expect(json["duration_mins"] as? Int == 60)
        let rate = try #require(json["hourly_rate"] as? [String: Any])
        #expect(rate["amount"] as? Int == 5000)
        #expect(rate["currency"] as? String == "CAD")
        #expect(json["is_free"] as? Bool == false)
        #expect(json["expertise_tag_ids"] as? [String] == ["tag-1", "tag-2"])
        #expect(json["description"] == nil)
        #expect(json["icon_slug"] == nil)
    }

    @Test("an empty tag list still encodes, so the server clears the tags")
    func emptyTagListEncodes() throws {
        let json = try Self.json(expertiseTagIds: [])

        #expect((json["expertise_tag_ids"] as? [String]) == [])
    }
}
