//
//  PastBooking.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Display model for a booking that has already happened (or was
/// cancelled/missed/expired/declined). Backed by `ClientBookingItem` with
/// `BookingStatus` in the past bucket.
struct PastBooking: Identifiable, Hashable {
    let id: UUID
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let status: PastBookingStatus
    /// Truncated preview of the client's private note on this booking,
    /// surfaced from `ClientBookingItem.private_note_preview`. `nil` when
    /// no note has been written.
    let privateNotePreview: String?
}
