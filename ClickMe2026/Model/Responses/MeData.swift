//
//  MeData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// `GET /me` — authenticated user's identity from the verified JWT payload.
struct MeData: Decodable {
    let id: UUID
    let email: String
    let role: UserRole
}
