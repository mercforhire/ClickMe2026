//
//  ExpertTopicRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-10.
//  Copyright © 2026 Q42. All rights reserved.
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

/// Body for `PATCH /expert/topics/:id`. Partial merge — send only the
/// fields you want to change. See `CreateExpertTopicRequest` for the
/// `isFree` placement rationale.
///
/// On `expertiseTagIds`: omit to leave unchanged, `[]` to clear, an
/// array to replace outright (destructive semantics — mirrors the
/// server contract).
struct UpdateExpertTopicRequest: Encodable {
    struct HourlyRate: Encodable {
        let amount: Int
        let currency: String
    }

    let title: String?
    let description: String?
    let durationMins: Int?
    let hourlyRate: HourlyRate?
    let isFree: Bool?
    let iconSlug: String?
    let expertiseTagIds: [String]?
}
