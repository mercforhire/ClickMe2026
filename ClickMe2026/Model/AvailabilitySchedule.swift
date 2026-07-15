//
//  AvailabilityScheduleEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct AvailabilityScheduleEntity: Codable {
    let id: UUID
    let expertId: UUID
    let timezoneId: String
    let monday: JSONValue
    let tuesday: JSONValue
    let wednesday: JSONValue
    let thursday: JSONValue
    let friday: JSONValue
    let saturday: JSONValue
    let sunday: JSONValue
    let updatedAt: Date
}
