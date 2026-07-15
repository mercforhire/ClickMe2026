//
//  ExpertBookingSummary.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Post-session summary returned by `GET /expert/bookings/{id}/summary`.
///
/// x-discrepancy #6: `keyTakeaways` is a plain string (not an `[{ id, text }]`
/// array as the spec describes); `client_feedback` and the resource URLs
/// (`call_recording_url`, `shared_notes_url`) are absent.
///
/// Status-dependent fields: `completed` adds `keyTakeaways` + `resources` (null);
/// `cancelled` adds `cancellationReason`; `missed` adds `noShowParty`.
struct ExpertBookingSummary: Decodable {
    struct Client: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
    }

    struct SessionDetails: Decodable {
        let topic: String?
        let startTime: Date
        let endTime: Date
        let status: BookingStatusMeta
    }

    let bookingId: UUID
    let client: Client
    let sessionDetails: SessionDetails
    let keyTakeaways: String?
    /// Phase 6 placeholder, currently always null.
    let resources: JSONValue?
    let cancellationReason: String?
    let noShowParty: String?
}
