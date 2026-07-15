//
//  PastBooking.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
}
