//
//  WeeklyEarningsData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `GET /expert/earnings/weekly`.
///
/// Week boundaries are anchored to Monday in the expert's IANA timezone
/// (falls back to UTC when the expert has no availability schedule row).
/// Amounts are integer minor units (cents for USD).
struct WeeklyEarningsData: Decodable {
    /// `YYYY-MM-DD` — Monday of the requested week (in the expert's tz).
    let weekStart: String
    /// `YYYY-MM-DD` — Sunday of the same week (in the expert's tz).
    let weekEnd: String
    /// Sum of session gross earnings in minor units.
    let grossAmount: Int
    /// Sum of stored per-booking net (gross − commission) in minor units.
    /// Client renders this as the headline "This Week" figure.
    let netAmount: Int
    /// ISO 3-letter uppercase (e.g. `"USD"`). Falls back to `"USD"` on
    /// zero-session weeks.
    let currency: String
    /// Number of completed sessions in the week; 0 for empty weeks.
    let sessionCount: Int
}
