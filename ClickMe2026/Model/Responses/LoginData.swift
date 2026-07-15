//
//  LoginData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// `POST /auth/login` success payload — Supabase JWT plus profile snapshot.
struct LoginData: Decodable {
    let token: String
    let user: AuthUser
}
