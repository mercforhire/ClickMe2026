//
//  AuthUser.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Authenticated user's profile snapshot returned at login/signup.
///
/// `roles` is a set — every account has `client` by default; experts
/// additionally have `expert`. Check `roles.contains(.expert)` when
/// deciding whether to expose expert-mode UI.
struct AuthUser: Decodable {
    let id: UUID
    let firstName: String
    let lastName: String
    let roles: [UserRole]
    let avatarUrl: String?
}
