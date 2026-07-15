//
//  ClickMeAPI+Clients.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    /// `GET /expert/clients/:id` — the expert-facing view of one of the
    /// expert's clients. Returns public profile fields (name, avatar, bio,
    /// location, languages, member-since) plus aggregate relationship
    /// stats (total sessions, first/last session date). Excludes email
    /// and phone.
    func getClientProfile(id: UUID) async throws -> SuccessDataResponse<ExpertClientProfileData> {
        try await service.httpRequest(url: url(.getClientProfile, id: id), method: .get)
    }
}
