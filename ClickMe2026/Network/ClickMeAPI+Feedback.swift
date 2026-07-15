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

    func submitFeedback(
        typeId: String,
        details: String,
        email: String? = nil,
        metadata: [String: Any]? = nil
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["type_id": typeId, "details": details]
        if let email { params["email"] = email }
        if let metadata { params["metadata"] = metadata }
        return try await service.httpRequest(url: url(.submitFeedback), method: .post, parameters: params)
    }
}
