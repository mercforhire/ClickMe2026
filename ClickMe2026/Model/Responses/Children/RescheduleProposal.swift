//
//  RescheduleProposal.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Who authored the pending reschedule. Drives which side sees the
/// Accept/Decline affordance vs. the "awaiting response" banner: the
/// counterparty acts, the initiator waits.
enum RescheduleInitiator: String, Decodable {
    case client
    case expert
}

/// Full reschedule payload attached to a booking-detail response when
/// `status == pending_reschedule`. Both `ClientBookingDetail.reschedule`
/// and `ExpertBookingDetail.reschedule` decode this identical shape.
///
/// Note: the booking's outer `start_time` / `end_time` remain on the
/// **current** (unchanged) slot until the counterparty accepts — so
/// clients can render "moving from → moving to" side by side.
///
/// Race note: `initiatedBy` reflects whoever proposed *most recently* —
/// last-write-wins overwrite is legal on the server. Always drive
/// "who accepts" off this value, not off remembered state.
struct RescheduleProposal: Decodable, Hashable {
    let proposedStart: Date
    let proposedEnd: Date
    /// Caller's IANA timezone at proposal time (e.g. "America/Toronto").
    let proposedTimezone: String
    let initiatedBy: RescheduleInitiator
    /// Optional message the proposer attached — surfaced in the banner
    /// so the counterparty sees the "why" alongside the proposed slot.
    let note: String?
    let createdAt: Date
}

/// Slim reschedule payload attached to each row in the booking-list
/// responses (`GET /(client|expert)/bookings`). Enough to render a
/// "Reschedule proposed" badge on the card without pulling the full
/// detail record.
struct ReschedulePreview: Decodable, Hashable {
    let proposedStart: Date
    let initiatedBy: RescheduleInitiator
}
