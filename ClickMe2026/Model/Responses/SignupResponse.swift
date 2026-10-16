//
//  SignupResponse.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Response payload for `POST /auth/signup`. Mirrors `LoginData`'s
/// `token`/`user` pair and adds an `emailVerified` flag so the client
/// can drive the Overview checklist without a follow-up call.
struct SignupResponse: Decodable {
    let token: String
    let user: AuthUser
    let emailVerified: Bool
    /// Rotating refresh credential — GoTrue issues one even for
    /// unconfirmed accounts, so signup + unverified users can still
    /// keep their session alive via `/auth/refresh`.
    let refreshToken: String
    /// Access-token expiry as unix epoch **seconds**.
    let expiresAt: Int
    /// Seconds until the access token expires.
    let expiresIn: Int
}

/// Response payload for `GET /auth/email/status` — polled by the verify
/// screen to know when the user has clicked the verification link.
struct EmailVerificationStatusResponse: Decodable {
    let verified: Bool
}
