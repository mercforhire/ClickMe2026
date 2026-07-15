//
//  ClickMeAPI+Call.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func joinCall(id: UUID) async throws -> SuccessDataResponse<JoinCallResponse> {
        try await service.httpRequest(url: url(.joinCall, id: id), method: .post)
    }

    func confirmCallConnection(
        id: UUID,
        connectionStatus: String,
        timestamp: String,
        method: String? = nil
    ) async throws -> SuccessDataResponse<ConfirmConnectionData> {
        var params: [String: Any] = ["connection_status": connectionStatus, "timestamp": timestamp]
        if let method { params["method"] = method }
        return try await service.httpRequest(
            url: url(.confirmCallConnection, id: id),
            method: .patch,
            parameters: params
        )
    }

    func endCall(id: UUID, actualDuration: Int, endReason: EndReason) async throws -> SuccessDataResponse<EndCallData> {
        try await service.httpRequest(
            url: url(.endCall, id: id),
            method: .post,
            parameters: ["actual_duration": actualDuration, "end_reason": endReason.rawValue]
        )
    }
}
