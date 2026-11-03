//
//  UserReportData.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Response payload for `POST /users/:id/report` (201).
/// Only `reportId` is useful client-side today (for optimistic
/// de-dupe if the user mashes Submit); `status` is always `"open"`
/// at creation. See `docs/ios/USER-REPORTING.md` §1.
struct UserReportData: Decodable {
    let reportId: UUID
    /// Always `"open"` at creation time.
    let status: String
    let createdAt: Date
}
