//
//  DeviceTokenEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct DeviceTokenEntity: Codable {
    let id: UUID
    let userId: UUID
    let deviceId: String
    let token: String
    let platform: String
    let appVersion: String?
    let createdAt: Date
    let updatedAt: Date
}
