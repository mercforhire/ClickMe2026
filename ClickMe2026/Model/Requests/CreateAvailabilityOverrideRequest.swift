//
//  CreateAvailabilityOverrideRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `POST /expert/availability/overrides` — date-specific override.
struct CreateAvailabilityOverrideRequest: Encodable {
    /// ISO 8601 date (YYYY-MM-DD).
    let date: String
    /// Empty array means unavailable that day.
    let slots: [TimeSlot]
    let note: String?
}
