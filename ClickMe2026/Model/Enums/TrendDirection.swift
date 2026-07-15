//
//  TrendDirection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Trend bucket comparison against the previous bucket. `neutral` when the
/// previous bucket is null or zero.
enum TrendDirection: String, Decodable {
    case up
    case down
    case neutral
}
