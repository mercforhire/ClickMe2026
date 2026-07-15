//
//  EndReason.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Reason a call session ended.
enum EndReason: String, Decodable {
    case completed
    case dropped
    case manualExit = "manual_exit"
}
