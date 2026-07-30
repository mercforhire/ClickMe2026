//
//  ClickMeAPI+Chats.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    /// `POST /chats/initiate` — get or create the 1:1 thread between the
    /// caller and `peerId`. Works from either side of a booking (the
    /// server treats it as a generic peer id, not role-specific).
    /// Idempotent: repeat calls return the existing thread.
    func initiateChat(peerId: UUID) async throws -> SuccessDataResponse<InitiateChatPayload> {
        try await service.httpRequest(
            url: url(.initiateChat),
            method: .post,
            parameters: ["peer_id": peerId.uuidString]
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

    /// `POST /chats/:id/send` — returns a minimal ack (`ChatSendAckData`)
    /// with just message id, status, and timestamp. The full `ChatMessageItem`
    /// row is available via `GET /chats/:id/messages`; callers reconcile
    /// a local optimistic insert against the ack rather than getting the
    /// whole record back.
    func sendChatMessage(
        id: UUID,
        type: MessageType,
        content: String,
        clientMsgId: String,
        attachments: [String] = []
    ) async throws -> SuccessDataResponse<ChatSendAckData> {
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
