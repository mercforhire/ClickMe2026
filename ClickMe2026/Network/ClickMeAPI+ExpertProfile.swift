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

/// Wrapper for the `POST /expert/topics` and `PATCH /expert/topics/:id`
/// responses — server nests the created/updated item under a `topic` key
/// inside the standard success envelope.
struct MyExpertTopicPayload: Decodable {
    let topic: ExpertTopicItem
}

extension ClickMeAPI {

    /// `GET /expert/profile` — expert's own aggregated profile. Includes
    /// `hourly_rate`, `expertise_tags`, and `setup_completed` — the fields
    /// the signup resume path needs to rehydrate a mid-flow account.
    func getExpertProfile() async throws -> SuccessDataResponse<ExpertProfileData> {
        try await service.httpRequest(url: url(.getExpertProfile), method: .get)
    }

    func setupExpertProfile(_ body: SetupExpertProfileRequest) async throws -> SuccessDataResponse<SetupExpertProfileData> {
        try await service.httpRequest(url: url(.setupExpertProfile), method: .patch, body: body)
    }

    /// The server responds with a thin confirmation payload (profile_id +
    /// updated_fields) — NOT the full profile. Callers that need the
    /// refreshed profile should follow up with
    /// `UserManager.refreshExpertProfile()` / `getExpertProfile()`.
    func updateExpertProfile(_ body: UpdateExpertProfileRequest) async throws -> SuccessDataResponse<UpdateExpertProfileData> {
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
    func createMyTopic(_ body: CreateExpertTopicRequest) async throws -> SuccessDataResponse<MyExpertTopicPayload> {
        try await service.httpRequest(url: url(.createMyTopic), method: .post, body: body)
    }

    /// `PATCH /expert/topics/:id` — partial merge update.
    func updateMyTopic(id: UUID, _ body: UpdateExpertTopicRequest) async throws -> SuccessDataResponse<MyExpertTopicPayload> {
        try await service.httpRequest(url: url(.updateMyTopic, id: id), method: .patch, body: body)
    }

    /// `DELETE /expert/topics/:id`. Returns 409 if the topic has active
    /// bookings — surface the server message to the user.
    func deleteMyTopic(id: UUID) async throws -> SuccessMessageResponse {
        try await service.httpRequest(url: url(.deleteMyTopic, id: id), method: .delete)
    }
}
