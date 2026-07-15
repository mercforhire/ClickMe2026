//
//  AvailabilityOverrideEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct AvailabilityOverrideEntity: Codable {
    let id: UUID
    let expertId: UUID
    let date: Date
    let slots: JSONValue
    let note: String?
    let createdAt: Date
}
