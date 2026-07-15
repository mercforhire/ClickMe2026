//
//  UserRole.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Platform role of an authenticated user. Shared by `AuthUser`, `MeData`,
/// and any other response carrying the role from the JWT.
enum UserRole: String, Decodable {
    case client
    case expert
}
