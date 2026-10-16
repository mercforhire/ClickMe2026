//
//  ExpertBookingItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Single booking row returned by `GET /expert/bookings`.
struct ExpertBookingItem: Decodable {
    struct Client: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
    }

    struct Session: Decodable {
        /// Client-facing session price. Same shape as
        /// `ExpertBookingDetail.Session.ConsultationFee` — the server
        /// mirrors the detail payload on the list rows after
        /// quick `261015-luj`.
        ///
        /// **Legacy — gross.** Keep for "Session price" surfaces only;
        /// read `earningsBreakdown.netAmount` for anything labeled
        /// "you earn".
        struct ConsultationFee: Decodable {
            let amount: Double
            let currency: String
            let label: String
        }

        let topic: String?
        let startTime: Date
        let endTime: Date
        let meetingType: MeetingType
        /// Optional — only present on backends shipping quick
        /// `261015-luj` onward. Pre-rollout cached list responses
        /// still decode.
        let consultationFee: ConsultationFee?
        /// Post-commission breakdown — see `EarningsBreakdown`. Optional
        /// so pre-rollout cached list responses still decode; render
        /// the `.unavailable` treatment when nil.
        let earningsBreakdown: EarningsBreakdown?
    }

    struct Actions: Decodable {
        /// True when now is within 5 minutes before start_time up to end_time.
        let canJoin: Bool
        let canReschedule: Bool
        let canMessage: Bool
    }

    let bookingId: UUID
    let client: Client
    let session: Session
    let status: BookingStatusMeta
    let actions: Actions
    /// Truncated preview (~140 chars) of the expert's private note on
    /// this booking. `nil` when no note exists. Full text lives at
    /// `GET /bookings/:id/note`.
    let privateNotePreview: String?
    /// Present when `status.code == pending_reschedule` — carries the
    /// proposed new start + initiator side. Full proposal lives on
    /// the detail response.
    let reschedule: ReschedulePreview?
}
