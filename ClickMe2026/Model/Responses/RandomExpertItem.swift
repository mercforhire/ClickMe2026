//
//  RandomExpertItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single expert item from the `random_experts` RPC. Shape is RPC-owned.
struct RandomExpertItem: Decodable {
    let expertId: UUID
    let fullName: String?
    let avatarUrl: String?
    let hourlyRateAmount: Int?
    let hourlyRateCurrency: String?
}
