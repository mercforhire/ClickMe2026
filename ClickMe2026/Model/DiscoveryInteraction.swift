//
//  DiscoveryInteractionEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct DiscoveryInteractionEntity: Codable {
    let id: UUID
    let userId: UUID
    let expertId: UUID
    let interactionType: String
    let source: String?
    let clientTimestamp: Date?
    let createdAt: Date
}
