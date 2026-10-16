//
//  PastSession.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Expert-side display model for a session that has already ended (or
/// was cancelled/declined/missed/expired). Mirrors the client's
/// `PastBooking` but with client-perspective fields (client name +
/// avatar in place of expert). Backed by `ExpertBookingItem` with a
/// terminal `BookingStatus`.
struct PastSession: Identifiable, Hashable {
    /// Local UUID — the wire `bookingId` lives in `bookingId` so
    /// SwiftUI's `Identifiable` conformance stays stable when the
    /// server sends duplicate ids across paginated fetches.
    let id = UUID()
    let bookingId: UUID
    let clientId: UUID
    let clientName: String
    let clientImageURL: String
    let topic: String
    let date: String
    let timeRange: String
    let status: PastBookingStatus
    /// Truncated preview of the expert's private note on this booking,
    /// surfaced from `ExpertBookingItem.private_note_preview`. `nil` when
    /// no note has been written.
    let privateNotePreview: String?
}
