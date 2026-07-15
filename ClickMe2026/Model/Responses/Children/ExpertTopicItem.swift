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
/// x-discrepancy #14: `hourlyRate` and `freeConsultationMinutes` are the
/// per-topic fields introduced for `GET /expert/topics` (my own list) and
/// are also mirrored back on the public `GET /experts/:id/topics` payload
/// for booking flows. Both are optional to keep this DTO decodable against
/// older responses that don't include them.
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
    let freeConsultationMinutes: Int?
}
