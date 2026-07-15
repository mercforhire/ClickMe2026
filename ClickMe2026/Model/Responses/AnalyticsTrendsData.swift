//
//  AnalyticsTrendsData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Time-series trend bucket from the `get_analytics_trends` RPC. The endpoint
/// returns a top-level array of these (use `[AnalyticsTrendItem]` for the body).
struct AnalyticsTrendItem: Decodable {
    let periodLabel: String
    let value: Int
    let trendDirection: TrendDirection
    let trendPct: Double
}

typealias AnalyticsTrendsData = [AnalyticsTrendItem]
