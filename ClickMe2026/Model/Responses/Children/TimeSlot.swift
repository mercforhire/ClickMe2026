//
//  TimeSlot.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A time window with HH:mm start and end times, aligned to 15-minute boundaries.
struct TimeSlot: Codable {
    let startTime: String
    let endTime: String
}
