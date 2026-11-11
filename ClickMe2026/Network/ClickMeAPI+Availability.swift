//
//  ClickMeAPI+Availability.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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

    /// `GET /experts/:id/availability?month=YYYY-MM`.
    /// - Parameters:
    ///   - id: The expert.
    ///   - month: `yyyy-MM`.
    ///   - excludeBookingId: The booking being rescheduled, so its own slot is not
    ///     shown as taken (BOOK-16). Sent as `exclude_booking_id` only when set.
    ///     The backend accepts a UUID in either case and ignores an invalid or
    ///     non-matching value (`availability.controller.js`). Make a Booking and
    ///     the expert reschedule picker leave it nil.
    func getExpertAvailability(
        id: UUID,
        month: String,
        excludeBookingId: UUID? = nil
    ) async throws -> SuccessDataResponse<ExpertAvailabilityData> {
        var parameters = ["month": month]
        if let excludeBookingId {
            parameters["exclude_booking_id"] = excludeBookingId.uuidString
        }
        return try await service.httpRequest(
            url: url(.getExpertAvailability, id: id),
            method: .get,
            parameters: parameters
        )
    }
}
