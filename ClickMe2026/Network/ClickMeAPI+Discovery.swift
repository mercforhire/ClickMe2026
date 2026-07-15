//
//  ClickMeAPI+Discovery.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getClientHome(page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<ClientHomeData> {
        try await service.httpRequest(
            url: url(.getClientHome),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    func searchExperts(
        q: String,
        category: String? = nil,
        minRate: Int? = nil,
        maxRate: Int? = nil,
        sort: String = "relevance",
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SuccessDataResponse<ExpertsSearchPayload> {
        var params: [String: Any] = ["q": q, "sort": sort, "page": page, "limit": limit]
        if let category { params["category"] = category }
        if let minRate { params["min_rate"] = minRate }
        if let maxRate { params["max_rate"] = maxRate }
        return try await service.httpRequest(url: url(.searchExperts), method: .get, parameters: params)
    }

    func getDiscoveryFeed(category: String? = nil, minRating: Int? = nil, page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<DiscoveryFeedPayload> {
        var params: [String: Any] = ["page": page, "limit": limit]
        if let category { params["category"] = category }
        if let minRating { params["min_rating"] = minRating }
        return try await service.httpRequest(url: url(.getDiscoveryFeed), method: .get, parameters: params)
    }

    func getRandomExperts(seed: Int? = nil, page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<RandomExpertsPayload> {
        var params: [String: Any] = ["page": page, "limit": limit]
        if let seed { params["seed"] = seed }
        return try await service.httpRequest(url: url(.getRandomExperts), method: .get, parameters: params)
    }

    func recordInteraction(
        expertId: UUID,
        interactionType: String,
        source: String? = nil,
        clientTimestamp: String? = nil
    ) async throws -> SuccessStatusOnlyResponse {
        var params: [String: Any] = [
            "expert_id": expertId.uuidString,
            "interaction_type": interactionType
        ]
        if let source { params["source"] = source }
        if let clientTimestamp { params["client_timestamp"] = clientTimestamp }
        return try await service.httpRequest(url: url(.recordInteraction), method: .post, parameters: params)
    }

    func getExpertDetails(id: UUID) async throws -> SuccessDataResponse<PublicProfileDetailsData> {
        try await service.httpRequest(url: url(.getExpertDetails, id: id), method: .get)
    }

    func getExpertTopics(id: UUID) async throws -> SuccessDataResponse<ExpertTopicsPayload> {
        try await service.httpRequest(url: url(.getExpertTopics, id: id), method: .get)
    }

    func getExpert(id: UUID) async throws -> SuccessDataResponse<PublicProfileData> {
        try await service.httpRequest(url: url(.getExpert, id: id), method: .get)
    }
}
