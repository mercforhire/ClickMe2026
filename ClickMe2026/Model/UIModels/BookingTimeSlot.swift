//
//  BookingTimeSlot.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// A single availability slot resolved from `ExpertAvailabilityData`.
struct BookingTimeSlot: Identifiable, Hashable {
    var id: Date { startTime }
    let startTime: Date
    let endTime: Date?
    let isAvailable: Bool

    /// The start time in the device's zone, following the device locale and its
    /// 12/24-hour setting (BOOK-04). Shared by the Make a Booking chips, the
    /// Reschedule picker and the Make a Booking summary line.
    var displayLabel: String {
        DateUtil.shortTime(startTime)
    }
}
