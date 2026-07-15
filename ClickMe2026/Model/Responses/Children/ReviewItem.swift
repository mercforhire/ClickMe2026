//
//  ReviewItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single public review. Only client-authored reviews are returned.
struct ReviewItem: Decodable {
    struct Reviewer: Decodable {
        let name: String?
        let avatarUrl: String?
    }

    struct SessionContext: Decodable {
        let topic: String?
        let date: String?
        let dateLabel: String?
    }

    let id: UUID
    let reviewer: Reviewer
    let sessionContext: SessionContext
    let rating: Int
    let comment: String?
    let createdAt: Date
    let verifiedBooking: Bool
}
