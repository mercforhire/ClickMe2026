//
//  ClientBookingFixtures.swift
//  ClickMe2026Tests
//
//  Shared `GET /client/bookings/:id` JSON builder for the Phase 3 view-model
//  suites. Fields a later plan needs (`decline_reason_code`,
//  `payment_action_required`, ...) go in through `extraFields`, so this file
//  does not change per plan.
//

import Foundation

enum ClientBookingFixtures {

    static let bookingId = "11111111-1111-4111-8111-111111111111"
    static let expertId = "22222222-2222-4222-8222-222222222222"
    static let topicId = "33333333-3333-4333-8333-333333333333"

    /// 2099-01-01T10:00:00Z. Far enough out that no clock-dependent branch fires by accident.
    static let defaultStart = Date(timeIntervalSince1970: 4_070_944_800)
    static let defaultEnd = defaultStart.addingTimeInterval(3600)

    // MARK: Detail

    /// `GET /client/bookings/:id` success envelope.
    ///
    /// - Parameters:
    ///   - reschedule: A raw JSON fragment (object or `null`), usually from `rescheduleJSON`.
    ///   - authorizationExpiresAt: A raw JSON fragment, for example `"\"2099-01-02T00:00:00.000Z\""` or `null`.
    ///   - canJoin: A raw JSON fragment: `true`, `false` or `null`.
    ///   - joinLink: A raw JSON fragment: a quoted string or `null`.
    ///   - extraFields: Extra top-level `"key":value` pairs, comma separated, with no leading comma.
    ///     Use only keys the builder does not already write.
    static func detailJSON(
        status: String = "confirmed",
        start: Date = defaultStart,
        end: Date = defaultEnd,
        meetingType: String = "in_app_voice",
        paymentStatus: String = "none",
        isFree: Bool = true,
        priceAmount: Int? = nil,
        currency: String = "USD",
        reschedule: String = "null",
        authorizationExpiresAt: String = "null",
        canJoin: String = "null",
        joinLink: String = "null",
        extraFields: String = ""
    ) -> Data {
        let price = priceAmount.map { #"{"amount":\#($0),"currency":"\#(currency)"}"# } ?? "null"
        let extra = extraFields.isEmpty ? "" : ",\n  \(extraFields)"
        return Data(#"""
        {"status":"success","data":{
          "booking_id":"\#(bookingId)",
          "status":"\#(status)",
          "start_time":"\#(iso(start))",
          "end_time":"\#(iso(end))",
          "meeting_type":"\#(meetingType)",
          "expert_timezone":"UTC",
          "payment_status":"\#(paymentStatus)",
          "topic":{"id":"\#(topicId)","title":"Free chat","duration_mins":30,"is_free":\#(isFree),"price":\#(price)},
          "expert":{"id":"\#(expertId)","full_name":"Ada Lovelace","avatar_url":null,"title":null},
          "join_link":\#(joinLink),
          "client_notes":null,
          "private_note":null,
          "reschedule":\#(reschedule),
          "authorization_expires_at":\#(authorizationExpiresAt),
          "can_join":\#(canJoin)\#(extra)
        }}
        """#.utf8)
    }

    /// The `reschedule` object of a `pending_reschedule` detail.
    static func rescheduleJSON(
        initiatedBy: String = "expert",
        proposedStart: Date = defaultStart.addingTimeInterval(86_400),
        proposedEnd: Date? = nil,
        note: String? = nil
    ) -> String {
        let end = proposedEnd ?? proposedStart.addingTimeInterval(3600)
        let noteJSON = note.map { "\"\($0)\"" } ?? "null"
        return #"""
        {"proposed_start":"\#(iso(proposedStart))","proposed_end":"\#(iso(end))","proposed_timezone":"UTC","initiated_by":"\#(initiatedBy)","note":\#(noteJSON),"created_at":"\#(iso(Date(timeIntervalSince1970: 4_070_000_000)))"}
        """#
    }

    // MARK: Helpers

    /// Fractional-seconds ISO-8601, the backend's timestamp shape.
    static func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    /// Builds a response for a stubbed request.
    static func response(
        for request: URLRequest,
        status: Int = 200,
        body: Data
    ) -> (HTTPURLResponse, Data) {
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (http, body)
    }

    /// `{"status":"error","code":...,"message":...}`.
    static func errorBody(code: String, message: String = "server text") -> Data {
        Data(#"{"status":"error","code":"\#(code)","message":"\#(message)"}"#.utf8)
    }

    static let successMessage = Data(#"{"status":"success","message":"ok"}"#.utf8)
}
