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

    /// `POST /auth/email/resend` — resend the verification email. No
    /// body — the request is authorized by the bearer token issued at
    /// signup. Rate-limited server-side (typical: 1 request per 30s).
    func resendVerificationEmail() async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.resendVerificationEmail),
            method: .post
        )
    }

    /// `GET /auth/email/status` — polled by the verify screen to detect
    /// when the user has clicked the verification link. Cheap read;
    /// mobile polls every ~5s while the verify screen is open.
    func checkEmailVerified() async throws -> SuccessDataResponse<EmailVerificationStatusResponse> {
        try await service.httpRequest(
            url: url(.checkEmailVerified),
            method: .get
        )
    }
}
