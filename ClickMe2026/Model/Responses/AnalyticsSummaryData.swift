//
//  AnalyticsSummaryData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Expert KPI summary from the `get_analytics_summary` RPC. `totalRevenue` is in
/// minor currency units (e.g. cents for USD).
struct AnalyticsSummaryData: Decodable {
    let totalBookings: Int
    let totalRevenue: Int
    let completionRate: Double
    let avgRating: Double
    let totalReviews: Int
}
