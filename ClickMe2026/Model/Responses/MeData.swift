//
//  MeData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// `GET /me` — authenticated user's identity from the verified JWT payload.
///
/// `roles` is a set — a user with `["client", "expert"]` can hit both
/// client- and expert-scoped endpoints. Every account has `client` by
/// default; experts additionally have `expert`.
struct MeData: Decodable {
    let id: UUID
    let email: String
    let roles: [UserRole]
}
