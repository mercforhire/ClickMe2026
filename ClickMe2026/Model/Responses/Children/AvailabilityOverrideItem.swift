//
//  AvailabilityOverrideItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A date-specific override of the expert's recurring schedule (expert-only view).
/// The `note` field is never returned to clients via the calendar endpoint.
struct AvailabilityOverrideItem: Decodable {
    let id: UUID
    /// ISO 8601 date (YYYY-MM-DD)
    let date: String
    let slots: [TimeSlot]
    let note: String?
}
