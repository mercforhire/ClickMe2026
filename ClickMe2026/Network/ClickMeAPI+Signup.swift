//
//  ClickMeAPI+Signup.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    /// `POST /auth/signup` — create a new account and receive a bearer
    /// token immediately, so the client can complete onboarding
    /// (`uploadAvatar`, `setupExpertProfile`) even before the
    /// verification email is opened.
    func signup(_ body: SignupRequest) async throws -> SuccessDataResponse<SignupResponse> {
        try await service.httpRequest(
            url: url(.signup),
            method: .post,
            parameters: [
                "username": body.username,
                "email": body.email,
                "password": body.password,
                "role": body.role
            ]
        )
    }

    /// `POST /auth/email/resend` — sends (or re-sends) the 6-digit
    /// verification code to the account's email address. No body — the
    /// request is authorized by the bearer token issued at signup.
    /// Rate-limited server-side (typical: 1 request per 30s).
    func resendVerificationEmail() async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.resendVerificationEmail),
            method: .post
        )
    }

    /// `POST /auth/email/verify` — submits the 6-digit code the user
    /// received via `resendVerificationEmail`. Success flips
    /// `profiles.email_verified` server-side. Wrong or expired code
    /// comes back as 422 with `code: "INVALID_CODE"`.
    func verifyEmailCode(_ body: VerifyEmailCodeRequest) async throws -> SuccessStatusOnlyResponse {
        try await service.httpRequest(
            url: url(.verifyEmailCode),
            method: .post,
            body: body
        )
    }

    /// `GET /auth/email/status` — legacy polling probe. Kept for edge
    /// cases (e.g. a user who verified via a different session/device);
    /// the signup flow no longer needs it now that verification is done
    /// inline via `verifyEmailCode`.
    func checkEmailVerified() async throws -> SuccessDataResponse<EmailVerificationStatusResponse> {
        try await service.httpRequest(
            url: url(.checkEmailVerified),
            method: .get
        )
    }
}
