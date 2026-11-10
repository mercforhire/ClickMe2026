//
//  BookingStatusDecodingTests.swift
//  ClickMe2026Tests
//
//  BOOK-18: a realtime `booking.update` with `rescheduled`, or with a status
//  this build does not know, must decode instead of failing. `RealtimeService`
//  decodes each socket event with `try?` and returns on failure, so a decode
//  error silently drops the whole event.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("BookingStatus decoding")
struct BookingStatusDecodingTests {

    /// Configured like `RealtimeService`'s decoder (snake_case keys, ISO-8601 dates).
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static let bookingId = "11111111-1111-4111-8111-111111111111"

    private static func realtimeJSON(status: String) -> Data {
        Data(#"{"booking_id":"\#(bookingId)","status":"\#(status)"}"#.utf8)
    }

    private static let knownStatuses: [(raw: String, expected: BookingStatus)] = [
        ("pending_approval", .pendingApproval),
        ("confirmed", .confirmed),
        ("pending_reschedule", .pendingReschedule),
        ("in_progress", .inProgress),
        ("completed", .completed),
        ("cancelled", .cancelled),
        ("declined", .declined),
        ("missed", .missed),
        ("expired", .expired)
    ]

    @Test("a realtime event with status rescheduled decodes as .rescheduled")
    func realtimeRescheduled() throws {
        let event = try Self.makeDecoder().decode(
            RealtimeBookingUpdateEvent.self,
            from: Self.realtimeJSON(status: "rescheduled")
        )
        #expect(event.status == .rescheduled)
        #expect(event.bookingId == UUID(uuidString: Self.bookingId))
    }

    @Test("a realtime event with an unrecognised status decodes as .unknown")
    func realtimeUnknown() throws {
        let event = try Self.makeDecoder().decode(
            RealtimeBookingUpdateEvent.self,
            from: Self.realtimeJSON(status: "something_new")
        )
        #expect(event.status == .unknown)
    }

    @Test("the nine existing wire statuses keep their cases")
    func knownRawValues() throws {
        for known in Self.knownStatuses {
            let event = try Self.makeDecoder().decode(
                RealtimeBookingUpdateEvent.self,
                from: Self.realtimeJSON(status: known.raw)
            )
            #expect(event.status == known.expected, "raw value \(known.raw)")
        }
    }

    @Test("decoding the same payload twice gives the same id and status")
    func decodeIsStable() throws {
        let data = Self.realtimeJSON(status: "something_new")
        let first = try Self.makeDecoder().decode(RealtimeBookingUpdateEvent.self, from: data)
        let second = try Self.makeDecoder().decode(RealtimeBookingUpdateEvent.self, from: data)
        #expect(first.bookingId == second.bookingId)
        #expect(first.status == second.status)
    }

    @Test("a missing status still throws")
    func missingStatusThrows() {
        let data = Data(#"{"booking_id":"\#(Self.bookingId)"}"#.utf8)
        #expect(throws: DecodingError.self) {
            try Self.makeDecoder().decode(RealtimeBookingUpdateEvent.self, from: data)
        }
    }

    @Test("a non-string status still throws")
    func nonStringStatusThrows() {
        let data = Data(#"{"booking_id":"\#(Self.bookingId)","status":42}"#.utf8)
        #expect(throws: DecodingError.self) {
            try Self.makeDecoder().decode(RealtimeBookingUpdateEvent.self, from: data)
        }
    }

    @Test("EndCallData with an unrecognised status decodes as .unknown")
    func endCallDataUnknown() throws {
        let json = """
        {
          "booking_id": "\(Self.bookingId)",
          "status": "something_new",
          "actual_duration_secs": 1800,
          "end_reason": "completed",
          "review_seam_triggered": false
        }
        """
        let data = try Self.makeDecoder().decode(EndCallData.self, from: Data(json.utf8))
        #expect(data.status == .unknown)
        #expect(data.endReason == .completed)
    }

    @Test("BookingStatusMeta with an unrecognised code decodes as .unknown")
    func metaUnknown() throws {
        let json = ##"{"label":"New","code":"something_new","color_accent":"#fff"}"##
        let meta = try Self.makeDecoder().decode(BookingStatusMeta.self, from: Data(json.utf8))
        #expect(meta.code == .unknown)
        #expect(meta.label == "New")
    }

    @Test("BookingStatusMeta with code rescheduled decodes as .rescheduled")
    func metaRescheduled() throws {
        let json = ##"{"label":"Rescheduled","code":"rescheduled","color_accent":"#fff"}"##
        let meta = try Self.makeDecoder().decode(BookingStatusMeta.self, from: Data(json.utf8))
        #expect(meta.code == .rescheduled)
    }
}
