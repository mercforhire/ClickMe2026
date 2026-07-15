//
//  ClickMeAPI+Account.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func requestAccountDeletion(password: String) async throws -> SuccessDataResponse<DeletionRequestData> {
        try await service.httpRequest(
            url: url(.requestAccountDeletion),
            method: .post,
            parameters: ["password": password]
        )
    }

    func deleteAccount(
        deletionToken: String,
        reasonCategory: String,
        feedbackDetails: String? = nil,
        confirmPermanentAction: Bool = true
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = [
            "deletion_token": deletionToken,
            "reason_category": reasonCategory,
            "confirm_permanent_action": confirmPermanentAction
        ]
        if let feedbackDetails { params["feedback_details"] = feedbackDetails }
        return try await service.httpRequest(url: url(.deleteAccount), method: .delete, parameters: params)
    }
}
