//
//  SignupResponse.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `POST /auth/signup`. Same shape as
/// `LoginData` — the mobile client stashes the token immediately and
/// treats the user as authenticated for the rest of the onboarding
/// flow, even though `emailVerified` is initially `false`.
struct SignupResponse: Decodable {
    let user: AuthUser
    let accessToken: String
    let emailVerified: Bool
}

/// Response payload for `GET /auth/email/status` — polled by the verify
/// screen to know when the user has clicked the verification link.
struct EmailVerificationStatusResponse: Decodable {
    let verified: Bool
}
