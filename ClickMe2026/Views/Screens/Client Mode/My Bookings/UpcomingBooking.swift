//
//  UpcomingBooking.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Display model for a booking that hasn't happened yet. Backed by
/// `ClientBookingItem` with `BookingStatus` in the upcoming bucket
/// (`pendingApproval / confirmed / pendingReschedule / inProgress`).
struct UpcomingBooking: Identifiable, Hashable {
    /// Server booking UUID from `ClientBookingItem.bookingId`. Needed for
    /// future API mutations (reschedule/cancel).
    let id: UUID
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let imageURL: String
}
