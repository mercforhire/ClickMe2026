//
//  FeedbackEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct FeedbackEntity: Codable {
    let id: UUID
    let userId: UUID
    let typeId: String
    let details: String
    let email: String?
    let metadata: JSONValue?
    let createdAt: Date
}
