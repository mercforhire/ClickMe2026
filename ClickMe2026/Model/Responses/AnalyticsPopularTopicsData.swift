//
//  AnalyticsPopularTopicsData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Expert's discussion topics ranked by booking count desc, from
/// the `get_popular_topics` RPC. `totalRevenue` is in minor currency units.
/// The endpoint returns a top-level array of these.
struct AnalyticsPopularTopicItem: Decodable {
    let topicId: UUID
    let title: String
    let bookingCount: Int
    let totalRevenue: Int
}

typealias AnalyticsPopularTopicsData = [AnalyticsPopularTopicItem]
