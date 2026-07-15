//
//  UpdateMyAvailabilityRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `PUT /expert/availability` — set the recurring 7-day schedule.
/// Empty array on a day means unavailable.
struct UpdateMyAvailabilityRequest: Encodable {
    struct Schedule: Encodable {
        let monday: [TimeSlot]
        let tuesday: [TimeSlot]
        let wednesday: [TimeSlot]
        let thursday: [TimeSlot]
        let friday: [TimeSlot]
        let saturday: [TimeSlot]
        let sunday: [TimeSlot]
    }

    let timezoneId: String
    let schedule: Schedule
}
