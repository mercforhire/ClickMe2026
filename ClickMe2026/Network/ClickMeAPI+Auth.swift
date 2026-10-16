//
//  ClickMeAPI+Auth.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func login(email: String, password: String) async throws -> SuccessDataResponse<LoginData> {
        try await service.httpRequest(
            url: url(.login),
            method: .post,
            parameters: ["email": email, "password": password]
        )
    }

    /// Exchanges a rotating refresh token for a fresh access + refresh
    /// pair. Public endpoint (no `Authorization` header) — the caller
    /// authorises via the body's `refresh_token`.
    ///
    /// The returned `refreshToken` supersedes the one passed in; store
    /// it immediately and discard the previous value. Replaying an old
    /// refresh token triggers server-side reuse detection and revokes
    /// the whole session.
    func refreshSession(refreshToken: String) async throws -> SuccessDataResponse<RefreshTokenData> {
        try await service.httpRequest(
            url: url(.refreshToken),
            method: .post,
            parameters: ["refresh_token": refreshToken]
        )
    }

    func forgotPassword(identity: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.forgotPassword),
            method: .post,
            parameters: ["identity": identity]
        )
    }

    func resetPassword(
        email: String,
        code: String,
        password: String,
        passwordConfirmation: String
    ) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.resetPassword),
            method: .post,
            parameters: [
                "email": email,
                "code": code,
                "password": password,
                "password_confirmation": passwordConfirmation
            ]
        )
    }
}
