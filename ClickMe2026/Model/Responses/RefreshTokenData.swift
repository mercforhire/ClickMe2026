//
//  RefreshTokenData.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// `POST /auth/refresh` success payload. Same token trio as `LoginData`
/// but without the user snapshot — the client keeps whatever cached
/// user it already had.
///
/// Reuse contract: the `refreshToken` returned here **rotates** — the
/// old value is invalidated the moment this response lands. Store the
/// new one immediately and discard the old one; replaying an old
/// refresh token triggers server-side reuse detection and revokes the
/// entire session (all future requests 401 until re-login).
struct RefreshTokenData: Decodable {
    let token: String
    let refreshToken: String
    /// Access-token expiry as unix epoch **seconds**.
    let expiresAt: Int
    /// Seconds until the (new) access token expires.
    let expiresIn: Int
}
