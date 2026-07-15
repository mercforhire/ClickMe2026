//
//  ClickMeAPI+ExpertProfile.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Wrapper for the `GET /expert/topics` list payload — same envelope shape as
/// the public `getExpertTopics(id:)` response so both endpoints can share
/// the `[ExpertTopicItem]` model.
struct MyExpertTopicsPayload: Decodable {
    let topics: [ExpertTopicItem]
}

extension ClickMeAPI {

    func setupExpertProfile(_ body: SetupExpertProfileRequest) async throws -> SuccessDataResponse<ExpertProfileData> {
        try await service.httpRequest(url: url(.setupExpertProfile), method: .patch, body: body)
    }

    func updateExpertProfile(_ body: UpdateExpertProfileRequest) async throws -> SuccessDataResponse<ExpertProfileData> {
        try await service.httpRequest(url: url(.updateExpertProfile), method: .patch, body: body)
    }

    // MARK: - Topics (my own)

    /// `GET /expert/topics` — the caller's own topics for the Manage
    /// Expertise editor.
    func getMyTopics() async throws -> SuccessDataResponse<MyExpertTopicsPayload> {
        try await service.httpRequest(url: url(.getMyTopics), method: .get)
    }

    /// `POST /expert/topics` — create a new topic. Returns the created item
    /// so we can insert the server's assigned UUID into the local list
    /// without re-fetching.
    func createMyTopic(_ body: CreateExpertTopicRequest) async throws -> SuccessDataResponse<ExpertTopicItem> {
        try await service.httpRequest(url: url(.createMyTopic), method: .post, body: body)
    }

    /// `PATCH /expert/topics/:id` — partial merge update.
    func updateMyTopic(id: UUID, _ body: UpdateExpertTopicRequest) async throws -> SuccessDataResponse<ExpertTopicItem> {
        try await service.httpRequest(url: url(.updateMyTopic, id: id), method: .patch, body: body)
    }

    /// `DELETE /expert/topics/:id`. Returns 409 if the topic has active
    /// bookings — surface the server message to the user.
    func deleteMyTopic(id: UUID) async throws -> SuccessMessageResponse {
        try await service.httpRequest(url: url(.deleteMyTopic, id: id), method: .delete)
    }
}
