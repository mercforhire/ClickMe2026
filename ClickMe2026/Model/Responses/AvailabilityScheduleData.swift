//
//  AvailabilityScheduleData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Expert's recurring availability schedule with timezone envelope.
/// All 7 day keys are always present; empty array means unavailable on that day.
struct AvailabilityScheduleData: Decodable {
    struct Timezone: Decodable {
        let id: String
        let displayName: String
        /// Signed hours offset (float; e.g. 5.5 for +5:30).
        let utcOffset: Double
    }

    struct RecurringSchedule: Decodable {
        let monday: [TimeSlot]
        let tuesday: [TimeSlot]
        let wednesday: [TimeSlot]
        let thursday: [TimeSlot]
        let friday: [TimeSlot]
        let saturday: [TimeSlot]
        let sunday: [TimeSlot]
    }

    let timezone: Timezone
    let recurringSchedule: RecurringSchedule
}
