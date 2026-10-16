//
//  ClickMeAPI+Booking.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Filter for `GET /client/bookings`. The server requires the `type` query
/// param — omitting it returns a 422 VALIDATION_ERROR.
enum ClientBookingsType: String {
    case upcoming
    case past
}

/// Filter for `GET /expert/bookings`. Same shape as the client-side
/// enum — omitting the `type` param yields upcoming-only, so the Past
/// tab on `UpcomingBookingsView` needs to fire an explicit `.past` call.
enum ExpertBookingsType: String {
    case upcoming
    case past
}

extension ClickMeAPI {

    func initiateBooking(expertId: UUID, topicId: UUID) async throws -> SuccessDataResponse<InitiateBookingData> {
        try await service.httpRequest(
            url: url(.initiateBooking),
            method: .post,
            parameters: ["expert_id": expertId.uuidString, "topic_id": topicId.uuidString]
        )
    }

    /// - `bookingAttemptId`: client-generated UUID that seeds the Stripe
    ///   idempotency key. Reuse across retries of the same attempt;
    ///   regenerate only for a genuinely new attempt (new slot / topic /
    ///   expert). Omitting it → 422; changing details under the same id
    ///   → 409 `BOOKING_ATTEMPT_CONFLICT`.
    func createPaymentIntent(
        expertId: UUID,
        topicId: UUID,
        selectedDate: String,
        timeSlot: String,
        durationMinutes: Int,
        bookingAttemptId: UUID,
        promoCode: String? = nil
    ) async throws -> PaymentIntentResponse {
        var params: [String: Any] = [
            "expert_id": expertId.uuidString.lowercased(),
            "topic_id": topicId.uuidString.lowercased(),
            "selected_date": selectedDate,
            "time_slot": timeSlot,
            "duration_minutes": durationMinutes,
            "booking_attempt_id": bookingAttemptId.uuidString.lowercased()
        ]
        if let promoCode { params["promo_code"] = promoCode }
        return try await service.httpRequest(url: url(.createPaymentIntent), method: .post, parameters: params)
    }

    /// - `paymentIntentId`: **optional** as of Phase 27.1. Omit to route
    ///   the request to the server's long-lead / save-card-first branch
    ///   (bookings whose session start is > 6 days out — where the
    ///   manual-capture PI flow cannot cover the lead time; charge is
    ///   scheduled ~24h before the session instead). Supply it for the
    ///   short-lead flow after collecting a card against
    ///   `/bookings/payment-intent`.
    func confirmBooking(
        paymentIntentId: String?,
        expertId: UUID,
        topicId: UUID,
        startTime: String,
        meetingType: MeetingType,
        stripePaymentMethodId: String,
        clientNotes: String? = nil,
        promoCode: String? = nil
    ) async throws -> SuccessDataResponse<ConfirmBookingData> {
        var params: [String: Any] = [
            "expert_id": expertId.uuidString.lowercased(),
            "topic_id": topicId.uuidString.lowercased(),
            "start_time": startTime,
            "meeting_type": meetingType.rawValue,
            "stripe_payment_method_id": stripePaymentMethodId
        ]
        if let paymentIntentId { params["payment_intent_id"] = paymentIntentId }
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

    func getClientBookings(
        type: ClientBookingsType,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SuccessDataResponse<ClientBookingsPayload> {
        try await service.httpRequest(
            url: url(.getClientBookings),
            method: .get,
            parameters: ["type": type.rawValue, "page": page, "limit": limit]
        )
    }

    /// `GET /client/transactions` — paginated payment history for the
    /// caller's own bookings, newest first. Key gotchas per the
    /// endpoint spec (`quick 260817-lxu`):
    ///
    /// - `paymentStatus` is an 11-value raw state machine, **not** the
    ///   4-value collapse used by `/client/bookings/:id`. Do not share
    ///   the enum between the two screens.
    /// - Amounts are minor units.
    /// - `refundedAt` is always `nil` — detect refunds via
    ///   `refundedAmount > 0` or `paymentStatus in (refunded,
    ///   partially_refunded)`.
    /// - **Pagination footgun:** requesting a page past the last one
    ///   returns HTTP 500, not an empty list. Callers must page
    ///   forward only while `pagination.hasMore == true` and treat
    ///   any 500 on `page > 1` as end-of-list — see
    ///   `ClientTransactionsViewModel.loadNextPageIfNeeded`.
    /// - Server clamps `limit` to `[1, 100]`. Server scoping is by
    ///   JWT — any client-supplied `client_id` is silently ignored.
    func getClientTransactions(
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SuccessDataResponse<ClientTransactionsData> {
        try await service.httpRequest(
            url: url(.getClientTransactions),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    func getClientBookingDetail(id: UUID) async throws -> SuccessDataResponse<ClientBookingDetail> {
        try await service.httpRequest(url: url(.getClientBookingDetail, id: id), method: .get)
    }

    /// - `stripePaymentMethodId`: **optional** as of Phase 27.1. Supply
    ///   a `pm_…` from `GET /me/payment-methods` when recovering from a
    ///   422 `PAYMENT_METHOD_REQUIRED` (the booking has no card on file,
    ///   or the card on file can't be prepared for future billing).
    ///   The server persists it on the booking row so a subsequent
    ///   accept — even one performed by the expert counterparty — can
    ///   convert to charge-at-T-24h.
    func rescheduleClientBooking(
        id: UUID,
        proposedStart: String,
        timezone: String,
        note: String? = nil,
        stripePaymentMethodId: String? = nil
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = ["proposed_start": proposedStart, "timezone": timezone]
        if let note { params["note"] = note }
        if let stripePaymentMethodId { params["stripe_payment_method_id"] = stripePaymentMethodId }
        return try await service.httpRequest(
            url: url(.rescheduleClientBooking, id: id),
            method: .patch,
            parameters: params
        )
    }

    /// Client accepts an expert-initiated reschedule proposal. Booking
    /// rolls forward to the proposed slot; response envelope carries
    /// the resulting `status` under `data`. Only the counterparty (i.e.
    /// non-initiator) may call this — the server 403s otherwise.
    ///
    /// - `stripePaymentMethodId`: same recovery mechanic as
    ///   `rescheduleClientBooking` — supply on retry after a 422
    ///   `PAYMENT_METHOD_REQUIRED`.
    func acceptClientReschedule(
        id: UUID,
        stripePaymentMethodId: String? = nil
    ) async throws -> SuccessMessageResponse {
        // Always send at least `{}` — the server rejects a body-less
        // POST with "expected object, received undefined", same pattern
        // as `acceptExpertBooking`.
        var params: [String: Any] = [:]
        if let stripePaymentMethodId { params["stripe_payment_method_id"] = stripePaymentMethodId }
        return try await service.httpRequest(
            url: url(.acceptClientReschedule, id: id),
            method: .post,
            parameters: params
        )
    }

    /// Client declines an expert-initiated reschedule proposal. Booking
    /// reverts to its previous status (typically `confirmed`) and the
    /// proposed slot is discarded. `reason` is optional metadata for
    /// the expert's benefit.
    func declineClientReschedule(id: UUID, reason: String? = nil) async throws -> SuccessMessageResponse {
        var params: [String: Any] = [:]
        if let reason { params["reason"] = reason }
        return try await service.httpRequest(
            url: url(.declineClientReschedule, id: id),
            method: .post,
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

    func getExpertBookings(
        type: ExpertBookingsType,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SuccessDataResponse<ExpertBookingsPayload> {
        try await service.httpRequest(
            url: url(.getExpertBookings),
            method: .get,
            parameters: ["type": type.rawValue, "page": page, "limit": limit]
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

    /// Expert accepts a client-initiated reschedule proposal.
    func acceptExpertReschedule(id: UUID) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.acceptExpertReschedule, id: id),
            method: .post,
            parameters: [:]
        )
    }

    /// Expert declines a client-initiated reschedule proposal. Booking
    /// reverts to previous status; `reason` is optional metadata surfaced
    /// to the client alongside the notification.
    func declineExpertReschedule(id: UUID, reason: String? = nil) async throws -> SuccessMessageResponse {
        var params: [String: Any] = [:]
        if let reason { params["reason"] = reason }
        return try await service.httpRequest(
            url: url(.declineExpertReschedule, id: id),
            method: .post,
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
        // Always send at least `{}` — server rejects a body-less POST with
        // `VALIDATION_ERROR: "expected object, received undefined"`.
        return try await service.httpRequest(
            url: url(.acceptExpertBooking, id: id),
            method: .post,
            parameters: params
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
        // Always send at least `{}` — server rejects a body-less POST with
        // `VALIDATION_ERROR: "expected object, received undefined"`.
        return try await service.httpRequest(
            url: url(.acceptBookingRequest, id: id),
            method: .post,
            parameters: params
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

    /// Client-scoped counterpart of `getBookingNote`. Same DTO shape;
    /// the server route is `/client/bookings/:id/note` and returns
    /// 404 for non-client callers (uniform-404 convention).
    func getClientBookingNote(id: UUID) async throws -> SuccessDataResponse<BookingNoteData> {
        try await service.httpRequest(url: url(.getClientBookingNote, id: id), method: .get)
    }

    /// Upsert the client's private note on a booking. POST replaces
    /// any existing note in-place.
    func createClientBookingNote(id: UUID, note: String) async throws -> SuccessDataResponse<BookingNoteData> {
        try await service.httpRequest(
            url: url(.createClientBookingNote, id: id),
            method: .post,
            parameters: ["note": note]
        )
    }
}
