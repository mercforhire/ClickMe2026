//
//  ExpertTopicRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-10.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `POST /expert/topics`.
struct CreateExpertTopicRequest: Encodable {
    struct HourlyRate: Encodable {
        let amount: Int
        let currency: String
    }

    let title: String
    let description: String?
    let durationMins: Int
    let hourlyRate: HourlyRate
    /// Category-taxonomy slug (e.g. `"marketing"`) — matches `CategoryIconMap`
    /// on the client. Nil → no icon (card renders a default).
    let iconSlug: String?
}

/// Body for `PATCH /expert/topics/:id`. Partial merge — send only the
/// fields you want to change.
struct UpdateExpertTopicRequest: Encodable {
    struct HourlyRate: Encodable {
        let amount: Int
        let currency: String
    }

    let title: String?
    let description: String?
    let durationMins: Int?
    let hourlyRate: HourlyRate?
    let iconSlug: String?
}
