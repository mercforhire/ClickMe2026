//
//  BookingTimeSlot.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single availability slot resolved from `ExpertAvailabilityData`.
struct BookingTimeSlot: Identifiable, Hashable {
    var id: Date { startTime }
    let startTime: Date
    let endTime: Date?
    let isAvailable: Bool

    var displayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f.string(from: startTime)
    }
}
