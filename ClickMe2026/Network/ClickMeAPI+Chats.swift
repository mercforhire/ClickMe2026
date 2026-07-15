//
//  ClickMeAPI+Chats.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func initiateChat(expertId: UUID) async throws -> SuccessDataResponse<InitiateChatPayload> {
        try await service.httpRequest(
            url: url(.initiateChat),
            method: .post,
            parameters: ["expert_id": expertId.uuidString]
        )
    }

    func getChats(page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<ChatsPayload> {
        try await service.httpRequest(
            url: url(.getChats),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    func getChatMessages(id: UUID, page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<ChatMessagesPayload> {
        try await service.httpRequest(
            url: url(.getChatMessages, id: id),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    func sendChatMessage(
        id: UUID,
        type: MessageType,
        content: String,
        clientMsgId: String,
        attachments: [String] = []
    ) async throws -> SuccessDataResponse<ChatMessageItem> {
        try await service.httpRequest(
            url: url(.sendChatMessage, id: id),
            method: .post,
            parameters: [
                "type": type.rawValue,
                "content": content,
                "client_msg_id": clientMsgId,
                "attachments": attachments
            ]
        )
    }

    func chatAction(id: UUID, action: String, reason: String? = nil, details: String? = nil) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["action": action]
        if let reason { params["reason"] = reason }
        if let details { params["details"] = details }
        return try await service.httpRequest(
            url: url(.chatActions, id: id),
            method: .post,
            parameters: params
        )
    }
}
