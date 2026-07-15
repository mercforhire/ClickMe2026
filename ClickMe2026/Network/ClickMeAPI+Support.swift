//
//  ClickMeAPI+Support.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getFAQs() async throws -> SuccessDataResponse<FaqsPayload> {
        try await service.httpRequest(url: url(.getFAQs), method: .get)
    }

    func searchFAQs(q: String) async throws -> SuccessDataResponse<FaqSearchPayload> {
        try await service.httpRequest(
            url: url(.searchFAQs),
            method: .get,
            parameters: ["q": q]
        )
    }

    func getFAQArticle(id: UUID) async throws -> SuccessDataResponse<FaqArticle> {
        try await service.httpRequest(url: url(.getFAQArticle, id: id), method: .get)
    }

    func createSupportTicket(
        type: String,
        subject: String,
        details: String,
        email: String? = nil,
        metadata: [String: Any]? = nil
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["type": type, "subject": subject, "details": details]
        if let email { params["email"] = email }
        if let metadata { params["metadata"] = metadata }
        return try await service.httpRequest(url: url(.createSupportTicket), method: .post, parameters: params)
    }
}
