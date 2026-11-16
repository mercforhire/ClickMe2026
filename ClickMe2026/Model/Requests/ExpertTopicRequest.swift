//
//  ExpertTopicRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Body for `POST /expert/topics`.
///
/// `isFree` is a top-level flag (not nested under `hourly_rate`) — the
/// server derives the response `price.is_free` from it. Required by the
/// backend even when a paid rate is supplied.
struct CreateExpertTopicRequest: Encodable {
    struct HourlyRate: Encodable {
        let amount: Int
        let currency: String
    }

    let title: String
    let description: String?
    let durationMins: Int
    let hourlyRate: HourlyRate
    let isFree: Bool
    /// Category-taxonomy slug (e.g. `"marketing"`) — matches `CategoryIconMap`
    /// on the client. Nil → no icon (card renders a default).
    let iconSlug: String?
    /// UUIDs from `GET /meta/expertise-tags`. Empty array → no tags on
    /// create. Capped at 3 server-side.
    let expertiseTagIds: [String]?
}

/// One field of a partial-update body that can be left alone, set, or cleared.
///
/// Swift's synthesized `Encodable` writes an optional with `encodeIfPresent`,
/// so a `nil` drops the key and the server keeps the stored value. That cannot
/// express "clear this field", which the server only accepts as an explicit
/// JSON `null`. This type carries the third state so the encoder can tell the
/// two apart.
enum NullableField<Value: Equatable>: Equatable {
    /// Leave the stored value alone: the key is not sent.
    case omit
    /// Replace the stored value: the key is sent with this value.
    case set(Value)
    /// Clear the stored value: the key is sent as JSON `null`.
    case null

    /// The field to send when an edit moves a stored value to a new one.
    ///
    /// - Parameters:
    ///   - old: The value the server holds now. `nil` means no value.
    ///   - new: The value after the edit. `nil` means the editor cleared it.
    /// - Returns: `.omit` when nothing changed, `.null` when a stored value
    ///   was cleared, `.set(new)` otherwise.
    static func patch(old: Value?, new: Value?) -> NullableField<Value> {
        switch (old, new) {
        case (nil, nil):
            return .omit
        case (.some, nil):
            return .null
        case let (old, .some(new)):
            return old == new ? .omit : .set(new)
        }
    }
}

/// Body for `PATCH /expert/topics/:id`. Partial merge — send only the
/// fields you want to change. See `CreateExpertTopicRequest` for the
/// `isFree` placement rationale.
///
/// On `expertiseTagIds`: omit to leave unchanged, `[]` to clear, an
/// array to replace outright (destructive semantics — mirrors the
/// server contract).
///
/// On `description` and `iconSlug` (D-15): the server accepts `null` on
/// PATCH to clear them, so each is a `NullableField` with three states:
/// `.omit` leaves the stored value, `.set` replaces it, `.null` clears it.
/// Build them with `NullableField.patch(old:new:)` so a key is only
/// sent when the expert changed it.
struct UpdateExpertTopicRequest: Encodable {
    struct HourlyRate: Encodable {
        let amount: Int
        let currency: String
    }

    let title: String?
    let description: NullableField<String>
    let durationMins: Int?
    let hourlyRate: HourlyRate?
    let isFree: Bool?
    let iconSlug: NullableField<String>
    let expertiseTagIds: [String]?

    /// camelCase raw values: `NetworkService` applies `.convertToSnakeCase`
    /// to the keys written by `encode(to:)` as well.
    private enum CodingKeys: String, CodingKey {
        case title, description, durationMins, hourlyRate, isFree, iconSlug, expertiseTagIds
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try encode(description, forKey: .description, into: &container)
        try container.encodeIfPresent(durationMins, forKey: .durationMins)
        try container.encodeIfPresent(hourlyRate, forKey: .hourlyRate)
        try container.encodeIfPresent(isFree, forKey: .isFree)
        try encode(iconSlug, forKey: .iconSlug, into: &container)
        try container.encodeIfPresent(expertiseTagIds, forKey: .expertiseTagIds)
    }

    private func encode(
        _ field: NullableField<String>,
        forKey key: CodingKeys,
        into container: inout KeyedEncodingContainer<CodingKeys>
    ) throws {
        switch field {
        case .omit: break
        case .set(let value): try container.encode(value, forKey: key)
        case .null: try container.encodeNil(forKey: key)
        }
    }
}
