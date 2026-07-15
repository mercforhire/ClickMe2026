//
//  ExpertTopicItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// An expert's discussion topic with server-formatted price label.
///
/// x-discrepancy #14: `hourlyRate` is the per-topic field introduced for
/// `GET /expert/topics` (my own list) and is also mirrored back on the
/// public `GET /experts/:id/topics` payload for booking flows. Optional to
/// keep this DTO decodable against older responses that don't include it.
struct ExpertTopicItem: Decodable {
    struct Price: Decodable {
        let amount: Int?
        let currency: String?
        let isFree: Bool
        let label: String?
    }

    struct HourlyRate: Decodable {
        let amount: Int
        let currency: String
    }

    let id: UUID
    let title: String
    let durationMins: Int?
    let description: String?
    let price: Price
    let hourlyRate: HourlyRate?
    /// Stable slug matching `CategoryIconMap` (e.g. `"marketing"`,
    /// `"finance"`). Client resolves it to an SF Symbol at render time;
    /// nil falls back to a decorative default.
    let iconSlug: String?
}
