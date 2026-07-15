//
//  ExpertAvailabilityData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Expert availability slot grid for a given month, expressed in the client's timezone.
/// Override notes are never included here (expert-only field).
struct ExpertAvailabilityData: Decodable {
    struct Day: Decodable {
        struct Slot: Decodable {
            let startTime: Date?
            let endTime: Date?
            let available: Bool?
            let held: Bool?
        }

        let date: String?
        let slots: [Slot]?
    }

    let expertTimezone: String
    let clientTimezone: String
    let month: String
    let days: [Day]
}
