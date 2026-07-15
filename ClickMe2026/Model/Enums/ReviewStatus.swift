//
//  ReviewStatus.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Review submission status. Currently always `published` (upsert-on-resubmit).
enum ReviewStatus: String, Decodable {
    case published
}
