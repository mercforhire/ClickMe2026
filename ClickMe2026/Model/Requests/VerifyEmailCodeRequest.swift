//
//  VerifyEmailCodeRequest.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Body for `POST /auth/email/verify` — the 6-digit code the user
/// received via `POST /auth/email/resend`.
struct VerifyEmailCodeRequest: Encodable {
    let code: String
}
