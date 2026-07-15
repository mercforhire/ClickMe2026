//
//  SignupResponse.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `POST /auth/signup`. Mirrors `LoginData`'s
/// `token`/`user` pair and adds an `emailVerified` flag so the client
/// can drive the Overview checklist without a follow-up call.
struct SignupResponse: Decodable {
    let token: String
    let user: AuthUser
    let emailVerified: Bool
}

/// Response payload for `GET /auth/email/status` — polled by the verify
/// screen to know when the user has clicked the verification link.
struct EmailVerificationStatusResponse: Decodable {
    let verified: Bool
}
