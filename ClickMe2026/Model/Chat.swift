//
//  ChatEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct ChatEntity: Codable {
    let id: UUID
    let clientId: UUID
    let expertId: UUID
    let isBlocked: Bool
    let lastMsgText: String?
    let lastMsgAt: Date?
    let lastMsgSenderId: UUID?
    let unreadCountClient: Int
    let unreadCountExpert: Int
    let createdAt: Date
    let updatedAt: Date
}
