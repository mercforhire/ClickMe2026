//
//  SignupRequest.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `POST /auth/signup` — creates a new account.
///
/// Server-side: creates the auth user, sends a verification email, and
/// returns the `AuthUser` snapshot + a bearer token so the mobile client
/// can proceed with the authenticated portion of onboarding
/// (`POST /user/profile/avatar`, `PATCH /expert/profile/setup`) even
/// before the verification email is opened.
///
/// `role` is set client-side based on which signup flow the user
/// entered — currently always `expert` for this flow.
struct SignupRequest: Encodable {
    let username: String
    let email: String
    let password: String
    let role: String
}
