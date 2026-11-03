//
//  ReportUserRequest.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Body for `POST /users/:id/report`. `details` is optional, max 1000
/// chars server-side — trimmed on the server. See
/// `docs/ios/USER-REPORTING.md` §1.
struct ReportUserRequest: Encodable {
    let reason: UserReportReason
    /// Free text. Nil / empty is accepted; the server stores "".
    let details: String?

    enum CodingKeys: String, CodingKey {
        case reason
        case details
    }
}
