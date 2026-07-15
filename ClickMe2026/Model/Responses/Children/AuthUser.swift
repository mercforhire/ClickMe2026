//
//  AuthUser.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Authenticated user's profile snapshot returned at login.
struct AuthUser: Decodable {
    let id: UUID
    let firstName: String
    let lastName: String
    let role: UserRole
    let avatarUrl: String?
}
