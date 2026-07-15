//
//  ClickMeAPI+Analytics.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getAnalyticsSummary(period: String = "last_30_days") async throws -> SuccessDataResponse<AnalyticsSummaryData> {
        try await service.httpRequest(
            url: url(.getAnalyticsSummary),
            method: .get,
            parameters: ["period": period]
        )
    }

    func getAnalyticsTrends(
        metric: String,
        interval: String = "monthly",
        period: String = "last_30_days"
    ) async throws -> SuccessDataResponse<AnalyticsTrendsData> {
        try await service.httpRequest(
            url: url(.getAnalyticsTrends),
            method: .get,
            parameters: ["metric": metric, "interval": interval, "period": period]
        )
    }

    func getPopularTopics(limit: Int = 10) async throws -> SuccessDataResponse<AnalyticsPopularTopicsData> {
        try await service.httpRequest(
            url: url(.getPopularTopics),
            method: .get,
            parameters: ["limit": limit]
        )
    }
}
