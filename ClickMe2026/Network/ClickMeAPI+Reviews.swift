//
//  ClickMeAPI+Reviews.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func postReview(
        bookingId: UUID,
        rating: Int,
        comment: String? = nil,
        tags: [String] = []
    ) async throws -> SuccessDataResponse<SubmitReviewData> {
        var params: [String: Any] = ["rating": rating, "tags": tags]
        if let comment { params["comment"] = comment }
        return try await service.httpRequest(
            url: url(.postReview, id: bookingId),
            method: .post,
            parameters: params
        )
    }

    func getReviewContext(bookingId: UUID) async throws -> SuccessDataResponse<ReviewContextData> {
        try await service.httpRequest(url: url(.getReviewContext, id: bookingId), method: .get)
    }

    func getExpertReviews(id: UUID, page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<ExpertReviewsPayload> {
        try await service.httpRequest(
            url: url(.getExpertReviews, id: id),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }
}
