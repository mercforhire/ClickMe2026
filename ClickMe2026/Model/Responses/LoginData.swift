//
//  LoginData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// `POST /auth/login` success payload — Supabase JWT plus profile snapshot.
struct LoginData: Decodable {
    let token: String
    let user: AuthUser
    /// Long-lived rotating credential used to obtain a new access token
    /// when the current one expires. Persisted in the Keychain and
    /// swapped on every `/auth/refresh` — reusing an old value trips
    /// the server's reuse detection and revokes the session.
    let refreshToken: String
    /// Access-token expiry as unix epoch **seconds** (not ms). Persisted
    /// alongside the tokens so cold-start restoration can decide
    /// whether to preflight a refresh.
    let expiresAt: Int
    /// Seconds remaining until the access token expires. Redundant with
    /// `expiresAt` (server computes both) — surfaced for callers that
    /// want a duration without doing wall-clock math.
    let expiresIn: Int
}
