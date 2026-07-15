//
//  ClickMeAPI+Availability.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getMyAvailability() async throws -> SuccessDataResponse<AvailabilityScheduleData> {
        try await service.httpRequest(url: url(.getMyAvailability), method: .get)
    }

    func updateMyAvailability(_ body: UpdateMyAvailabilityRequest) async throws -> SuccessMessageResponse {
        try await service.httpRequest(url: url(.updateMyAvailability), method: .put, body: body)
    }

    func getAvailabilityOverrides() async throws -> SuccessDataResponse<AvailabilityOverridesPayload> {
        try await service.httpRequest(url: url(.getAvailabilityOverrides), method: .get)
    }

    func createAvailabilityOverride(_ body: CreateAvailabilityOverrideRequest) async throws -> SuccessDataResponse<AvailabilityOverrideItem> {
        try await service.httpRequest(url: url(.createAvailabilityOverride), method: .post, body: body)
    }

    func deleteAvailabilityOverride(id: UUID) async throws -> SuccessMessageResponse {
        try await service.httpRequest(url: url(.deleteAvailabilityOverride, id: id), method: .delete)
    }

    func getExpertAvailability(id: UUID, month: String) async throws -> SuccessDataResponse<ExpertAvailabilityData> {
        try await service.httpRequest(
            url: url(.getExpertAvailability, id: id),
            method: .get,
            parameters: ["month": month]
        )
    }
}
