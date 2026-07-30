//
//  ClickMeAPI+Feedback.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getFeedbackTypes() async throws -> SuccessDataResponse<FeedbackTypesPayload> {
        try await service.httpRequest(url: url(.getFeedbackTypes), method: .get)
    }

    /// The server returns `{status:"success", data:{submission_id, submitted_at}}`
    /// on 201, not the `{status, message}` shape most other endpoints use.
    /// Decode with `SuccessStatusOnlyResponse` so we accept the payload
    /// without caring about the specific data fields — the caller
    /// discards the response anyway.
    func submitFeedback(
        typeId: String,
        details: String,
        email: String? = nil,
        metadata: [String: Any]? = nil
    ) async throws -> SuccessStatusOnlyResponse {
        var params: [String: Any] = ["type_id": typeId, "details": details]
        if let email { params["email"] = email }
        if let metadata { params["metadata"] = metadata }
        return try await service.httpRequest(url: url(.submitFeedback), method: .post, parameters: params)
    }
}
