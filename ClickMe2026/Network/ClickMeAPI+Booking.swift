//
//  ClickMeAPI+Booking.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func initiateBooking(expertId: UUID, topicId: UUID) async throws -> SuccessDataResponse<InitiateBookingData> {
        try await service.httpRequest(
            url: url(.initiateBooking),
            method: .post,
            parameters: ["expert_id": expertId.uuidString, "topic_id": topicId.uuidString]
        )
    }

    func createPaymentIntent(
        expertId: UUID,
        topicId: UUID,
        selectedDate: String,
        timeSlot: String,
        durationMinutes: Int,
        promoCode: String? = nil
    ) async throws -> PaymentIntentResponse {
        var params: [String: Any] = [
            "expert_id": expertId.uuidString,
            "topic_id": topicId.uuidString,
            "selected_date": selectedDate,
            "time_slot": timeSlot,
            "duration_minutes": durationMinutes
        ]
        if let promoCode { params["promo_code"] = promoCode }
        return try await service.httpRequest(url: url(.createPaymentIntent), method: .post, parameters: params)
    }

    func confirmBooking(
        paymentIntentId: String,
        expertId: UUID,
        topicId: UUID,
        startTime: String,
        meetingType: MeetingType,
        stripePaymentMethodId: String,
        clientNotes: String? = nil,
        promoCode: String? = nil
    ) async throws -> SuccessDataResponse<ConfirmBookingData> {
        var params: [String: Any] = [
            "payment_intent_id": paymentIntentId,
            "expert_id": expertId.uuidString,
            "topic_id": topicId.uuidString,
            "start_time": startTime,
            "meeting_type": meetingType.rawValue,
            "stripe_payment_method_id": stripePaymentMethodId
        ]
        if let clientNotes { params["client_notes"] = clientNotes }
        if let promoCode { params["promo_code"] = promoCode }
        return try await service.httpRequest(url: url(.confirmBooking), method: .post, parameters: params)
    }

    func requestBooking(
        expertId: UUID,
        topicId: UUID,
        scheduledStart: String,
        durationMinutes: Int,
        meetingType: MeetingType,
        timezone: String,
        clientNotes: String? = nil
    ) async throws -> SuccessDataResponse<BookingRequestData> {
        var params: [String: Any] = [
            "expert_id": expertId.uuidString,
            "topic_id": topicId.uuidString,
            "scheduled_start": scheduledStart,
            "duration_minutes": durationMinutes,
            "meeting_type": meetingType.rawValue,
            "timezone": timezone
        ]
        if let clientNotes { params["client_notes"] = clientNotes }
        return try await service.httpRequest(url: url(.requestBooking), method: .post, parameters: params)
    }

    func getClientBookings(page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<ClientBookingsPayload> {
        try await service.httpRequest(
            url: url(.getClientBookings),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    func rescheduleClientBooking(
        id: UUID,
        proposedStart: String,
        timezone: String,
        note: String? = nil
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["proposed_start": proposedStart, "timezone": timezone]
        if let note { params["note"] = note }
        return try await service.httpRequest(
            url: url(.rescheduleClientBooking, id: id),
            method: .patch,
            parameters: params
        )
    }

    func cancelClientBooking(id: UUID, reason: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.cancelClientBooking, id: id),
            method: .post,
            parameters: ["reason": reason]
        )
    }

    func getExpertBookings(page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<ExpertBookingsPayload> {
        try await service.httpRequest(
            url: url(.getExpertBookings),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    func getExpertBookingDetails(id: UUID) async throws -> SuccessDataResponse<ExpertBookingDetail> {
        try await service.httpRequest(url: url(.getExpertBookingDetails, id: id), method: .get)
    }

    func getExpertBookingSummary(id: UUID) async throws -> SuccessDataResponse<ExpertBookingSummary> {
        try await service.httpRequest(url: url(.getExpertBookingSummary, id: id), method: .get)
    }

    func updateBookingTakeaways(id: UUID, keyTakeaways: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.updateBookingTakeaways, id: id),
            method: .put,
            parameters: ["key_takeaways": keyTakeaways]
        )
    }

    func updateBookingStatus(
        id: UUID,
        status: String,
        noShowParty: String? = nil,
        internalNote: String? = nil
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["status": status]
        if let noShowParty { params["no_show_party"] = noShowParty }
        if let internalNote { params["internal_note"] = internalNote }
        return try await service.httpRequest(
            url: url(.updateBookingStatus, id: id),
            method: .patch,
            parameters: params
        )
    }

    func rescheduleExpertBooking(
        id: UUID,
        proposedStart: String,
        timezone: String,
        note: String? = nil
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["proposed_start": proposedStart, "timezone": timezone]
        if let note { params["note"] = note }
        return try await service.httpRequest(
            url: url(.rescheduleExpertBooking, id: id),
            method: .patch,
            parameters: params
        )
    }

    func cancelExpertBooking(id: UUID, reason: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.cancelExpertBooking, id: id),
            method: .post,
            parameters: ["reason": reason]
        )
    }

    func acceptExpertBooking(id: UUID, message: String? = nil) async throws -> SuccessMessageResponse {
        var params: [String: Any] = [:]
        if let message { params["message"] = message }
        return try await service.httpRequest(
            url: url(.acceptExpertBooking, id: id),
            method: .post,
            parameters: params.isEmpty ? nil : params
        )
    }

    func declineExpertBooking(id: UUID, reasonCode: String, reasonText: String? = nil) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["reason_code": reasonCode]
        if let reasonText { params["reason_text"] = reasonText }
        return try await service.httpRequest(
            url: url(.declineExpertBooking, id: id),
            method: .post,
            parameters: params
        )
    }

    func getBookingRequests(page: Int = 1, limit: Int = 20) async throws -> SuccessDataResponse<BookingRequestsPayload> {
        try await service.httpRequest(
            url: url(.getBookingRequests),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    func getBookingRequest(id: UUID) async throws -> SuccessDataResponse<BookingRequestDetail> {
        try await service.httpRequest(url: url(.getBookingRequest, id: id), method: .get)
    }

    func acceptBookingRequest(id: UUID, message: String? = nil) async throws -> SuccessMessageResponse {
        var params: [String: Any] = [:]
        if let message { params["message"] = message }
        return try await service.httpRequest(
            url: url(.acceptBookingRequest, id: id),
            method: .post,
            parameters: params.isEmpty ? nil : params
        )
    }

    func declineBookingRequest(id: UUID, reasonCode: String, reasonText: String? = nil) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["reason_code": reasonCode]
        if let reasonText { params["reason_text"] = reasonText }
        return try await service.httpRequest(
            url: url(.declineBookingRequest, id: id),
            method: .post,
            parameters: params
        )
    }

    func getBookingNote(id: UUID) async throws -> SuccessDataResponse<BookingNoteData> {
        try await service.httpRequest(url: url(.getBookingNote, id: id), method: .get)
    }

    func createBookingNote(id: UUID, note: String) async throws -> SuccessDataResponse<BookingNoteData> {
        try await service.httpRequest(
            url: url(.createBookingNote, id: id),
            method: .post,
            parameters: ["note": note]
        )
    }
}
