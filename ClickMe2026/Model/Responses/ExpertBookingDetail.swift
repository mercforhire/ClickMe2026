//
//  ExpertBookingDetail.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Full detail returned by `GET /expert/bookings/{id}/details`.
///
/// x-discrepancy #5: `client.headline`, `client.rating`, `client.review_count`,
/// `session.schedule.date`/`date_label`/`time_range`/`timezone`, and a `connection`
/// object from the API reference spec are NOT returned.
struct ExpertBookingDetail: Decodable {
    struct Client: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
    }

    struct Session: Decodable {
        struct ConsultationFee: Decodable {
            let amount: Double
            let currency: String
            let label: String
        }

        struct Schedule: Decodable {
            let startTime: Date
            let endTime: Date
        }

        let topicTitle: String?
        /// **Legacy — client-facing session price**, not the expert's
        /// take-home. Keep for "Session price" surfaces; read
        /// `earningsBreakdown.netAmount` for anything labeled "you earn"
        /// per the Expert Earnings Breakdown spec (§2).
        let consultationFee: ConsultationFee
        let schedule: Schedule
        let meetingType: MeetingType
        /// Post-commission breakdown — see `EarningsBreakdown`. Optional
        /// so pre-rollout cached responses still decode; render the
        /// `.unavailable` treatment when nil.
        let earningsBreakdown: EarningsBreakdown?
    }

    struct PreparationNotes: Decodable {
        /// `client_notes` from the bookings row.
        let text: String?
    }

    struct Actions: Decodable {
        let canJoin: Bool
        let canReschedule: Bool
        let canCancel: Bool
        let canMessage: Bool
    }

    let bookingId: UUID
    let status: BookingStatusMeta
    let client: Client
    let session: Session
    let preparationNotes: PreparationNotes
    let actions: Actions
    /// Full text of the expert's own private note on this booking. `nil`
    /// when none has been written. Same source of truth as
    /// `GET /bookings/:id/note`, folded into the detail response so the
    /// summary screen can render it inline.
    let expertPrivateNote: String?
    /// Populated when `status.code == "pending_reschedule"` — full
    /// proposal from the initiator so the counterparty can accept /
    /// decline in-line.
    let reschedule: RescheduleProposal?
    /// End of the Stripe authorization window (`authorized_at + ~6d`)
    /// on the client's live card hold. `nil` for free / long-lead /
    /// already-captured / terminal bookings.
    ///
    /// **Non-gating as of Phase 27.1** — moving the session past this
    /// instant is no longer refused; the server voids the client's
    /// hold and converts the booking to the charge-at-T-24h model. Do
    /// NOT filter or disable reschedule-picker slots against this
    /// field. The expert side has no direct disclosure use for this
    /// value today.
    let authorizationExpiresAt: Date?
}
