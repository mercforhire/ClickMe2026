//
//  SuccessStatusOnlyResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Minimal success envelope — `{ status: "success" }`. Used by fire-and-forget
/// operations such as `POST /discovery/interact` (202).
///
/// x-discrepancy #25: the planning spec says `{ "status": "logged" }` but the
/// controller returns `{ "status": "success" }`. Documented code-as-is.
struct SuccessStatusOnlyResponse: Decodable {
    let status: String
}
