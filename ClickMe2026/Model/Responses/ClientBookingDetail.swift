//
//  ClientBookingDetail.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Full detail for a single booking from `GET /client/bookings/:id`.
/// Superset of `ClientBookingItem` — includes topic pricing, expert title,
/// expert timezone, payment status, join link, and the client's own note.
struct ClientBookingDetail: Decodable {

    struct Topic: Decodable {
        struct Price: Decodable {
            let amount: Int?
            let currency: String?
        }
        let id: UUID
        let title: String
        let durationMins: Int?
        /// Observed at the topic level (sibling of `price`), not inside it.
        let isFree: Bool
        let price: Price?
    }

    struct Expert: Decodable {
        let id: UUID
        let fullName: String?
        let avatarUrl: String?
        let title: String?
    }

    let bookingId: UUID
    /// Raw booking status enum value ("confirmed", "pending_approval", …).
    let status: String
    let startTime: Date
    let endTime: Date
    let meetingType: MeetingType
    /// Expert's IANA timezone identifier (e.g. "America/Sao_Paulo").
    let expertTimezone: String?
    /// Server-driven payment status: `held / captured / refunded / none`.
    /// Free topics report `none`.
    let paymentStatus: String
    let topic: Topic
    let expert: Expert
    /// External meeting URL (Skype/Zoom) or in-app deep link. `nil` when
    /// there's nothing to link to yet.
    let joinLink: String?
    /// Note the client attached at booking time. `nil` when absent.
    let clientNotes: String?
    /// Full text of the client's own private note on this booking. `nil`
    /// when none has been written. Same source of truth as
    /// `GET /client/bookings/:id/note`, folded into the detail response
    /// so the summary screen can render it inline.
    let privateNote: String?
    /// Populated when `status == "pending_reschedule"` — full proposal
    /// (proposed slot, timezone, initiator, note, created_at) so the
    /// counterparty can render a decision UI without another fetch.
    let reschedule: RescheduleProposal?
    /// End of the Stripe authorization window (`authorized_at + ~6d`)
    /// for bookings that carry a live hold. `nil` for free / long-lead
    /// / already-captured / terminal bookings.
    ///
    /// **Non-gating as of Phase 27.1** — moving the session past this
    /// instant is no longer refused; the server voids the hold and
    /// converts the booking to the charge-at-T-24h model. Do NOT filter
    /// or disable reschedule-picker slots against this field. Its only
    /// remaining purpose is triggering the confirm-step payment-timing
    /// disclosure when the proposed session END is past this timestamp.
    let authorizationExpiresAt: Date?
}
