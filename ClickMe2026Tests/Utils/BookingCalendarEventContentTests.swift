//
//  BookingCalendarEventContentTests.swift
//  ClickMe2026Tests
//
//  G-06-1-summary-calendar / D-13: Booking Confirmed and the expert Booking
//  Summary build the same calendar event through one builder, titled
//  `ClickMe · {topic} with {name}`. Dates are fixed, never `Date()`.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Booking calendar event content")
struct BookingCalendarEventContentTests {

    private let start = Date(timeIntervalSince1970: 1_795_000_000)
    private var end60: Date { start.addingTimeInterval(3_600) }

    // MARK: - Booking Confirmed parity and the summary view model

    @Test("the expert event equals the Booking Confirmed event for the same inputs")
    func expertEventMatchesConfirmed() {
        let event = BookingCalendarEventContent.expertEvent(
            topic: "Career coaching",
            clientName: "Jane D.",
            start: start,
            end: end60,
            meetingType: .inAppVoice,
            clientMessage: "Hello"
        )
        let confirmed = ExpertBookingConfirmationContent.confirmation(
            clientName: "Jane D.",
            clientImageURL: nil,
            topic: "Career coaching",
            start: start,
            end: end60,
            meetingType: .inAppVoice,
            clientMessage: "Hello"
        )
        #expect(event == confirmed.calendarPayload)
        #expect(event.title == "ClickMe \u{00B7} Career coaching with Jane D.")
        #expect(event.notes == "In-App Voice\nHello")
        #expect(event.startDate == start)
        #expect(event.endDate == end60)
    }

    @Test("parity holds with a blank client, no topic, Skype/Zoom and no message")
    func expertEventMatchesConfirmedWithFallbacks() {
        let event = BookingCalendarEventContent.expertEvent(
            topic: nil,
            clientName: "  ",
            start: start,
            end: end60,
            meetingType: .skypeZoom,
            clientMessage: nil
        )
        let confirmed = ExpertBookingConfirmationContent.confirmation(
            clientName: "  ",
            clientImageURL: nil,
            topic: nil,
            start: start,
            end: end60,
            meetingType: .skypeZoom,
            clientMessage: nil
        )
        #expect(event == confirmed.calendarPayload)
        #expect(event.title == "ClickMe \u{00B7} Session with Client")
        #expect(event.notes == "Skype/Zoom")
    }

    /// A minimal details payload (the shape in `ExpertCancelRefundLineTests`)
    /// with the status and preparation text varied.
    private static func decodeDetail(status: String, preparationText: String?) throws -> ExpertBookingDetail {
        let text = preparationText.map { "\"\($0)\"" } ?? "null"
        let json = """
        {"booking_id":"11111111-1111-4111-8111-111111111111",
         "status":{"label":"Status","code":"\(status)","color_accent":"green"},
         "client":{"id":"22222222-2222-4222-8222-222222222222","name":"Sam","avatar_url":null},
         "session":{"topic_title":"Algorithms",
                    "consultation_fee":{"amount":45,"currency":"CAD","label":"CA$45.00 / session"},
                    "schedule":{"start_time":"2027-01-15T18:00:00Z","end_time":"2027-01-15T18:30:00Z"},
                    "meeting_type":"in_app_voice"},
         "preparation_notes":{"text":\(text)},
         "actions":{"can_join":false,"can_reschedule":true,"can_cancel":true,"can_message":true}}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExpertBookingDetail.self, from: Data(json.utf8))
    }

    private static let summaryStart = Date(timeIntervalSince1970: 1_800_036_000) // 2027-01-15T18:00:00Z
    private static let summaryEnd = Date(timeIntervalSince1970: 1_800_037_800)   // 2027-01-15T18:30:00Z

    @Test("the summary view model builds the Booking Confirmed event and gates it on status and end")
    func summaryViewModel() throws {
        let viewModel = ExpertBookingSummaryViewModel(bookingId: UUID())
        #expect(viewModel.calendarEvent == nil)
        #expect(viewModel.showsAddToCalendar(at: Self.summaryStart) == false)

        viewModel.detail = try Self.decodeDetail(status: "confirmed", preparationText: "See you")
        let expected = BookingCalendarEventContent.expertEvent(
            topic: "Algorithms",
            clientName: "Sam",
            start: Self.summaryStart,
            end: Self.summaryEnd,
            meetingType: .inAppVoice,
            clientMessage: "See you"
        )
        #expect(viewModel.calendarEvent == expected)
        #expect(viewModel.calendarEvent?.startDate == Self.summaryStart)
        #expect(viewModel.calendarEvent?.endDate == Self.summaryEnd)
        #expect(viewModel.showsAddToCalendar(at: Self.summaryEnd.addingTimeInterval(-1)) == true)
        #expect(viewModel.showsAddToCalendar(at: Self.summaryEnd) == false)

        viewModel.detail = try Self.decodeDetail(status: "completed", preparationText: "See you")
        #expect(viewModel.showsAddToCalendar(at: Self.summaryStart.addingTimeInterval(-3_600)) == false)
    }

    // MARK: - Wording and offer rule

    @Test("title: topic and name trimmed, fallbacks for nil or blank, emoji and accents kept")
    func titleWording() {
        #expect(BookingCalendarEventContent.title(
            topic: "Career coaching", counterpartName: "Jane D.", counterpartFallback: "Client"
        ) == "ClickMe \u{00B7} Career coaching with Jane D.")
        #expect(BookingCalendarEventContent.title(
            topic: nil, counterpartName: "Jane", counterpartFallback: "Client"
        ) == "ClickMe \u{00B7} Session with Jane")
        #expect(BookingCalendarEventContent.title(
            topic: "   ", counterpartName: nil, counterpartFallback: "Client"
        ) == "ClickMe \u{00B7} Session with Client")
        #expect(BookingCalendarEventContent.title(
            topic: "  Maths  ", counterpartName: " \n ", counterpartFallback: "Expert"
        ) == "ClickMe \u{00B7} Maths with Expert")
        #expect(BookingCalendarEventContent.title(
            topic: " Café \u{1F680} ", counterpartName: " José \u{00C9}lan ", counterpartFallback: "Client"
        ) == "ClickMe \u{00B7} Café \u{1F680} with José \u{00C9}lan")
    }

    @Test("notes: the meeting type, then the trimmed message on a new line only when not blank")
    func notesWording() {
        #expect(BookingCalendarEventContent.notes(meetingType: .inAppVoice, message: nil) == "In-App Voice")
        #expect(BookingCalendarEventContent.notes(meetingType: .inAppVoice, message: "  ") == "In-App Voice")
        #expect(BookingCalendarEventContent.notes(meetingType: .skypeZoom, message: " See you ") == "Skype/Zoom\nSee you")
    }

    @Test("the client event reads the expert's name, with Expert and Session fallbacks")
    func clientEventWording() {
        let event = BookingCalendarEventContent.clientEvent(
            topic: "Free chat",
            expertName: "Ada Lovelace",
            start: start,
            end: end60,
            meetingType: .inAppVoice,
            clientMessage: "Looking forward"
        )
        #expect(event.title == "ClickMe \u{00B7} Free chat with Ada Lovelace")
        #expect(event.notes == "In-App Voice\nLooking forward")
        #expect(event.startDate == start)
        #expect(event.endDate == end60)

        let fallback = BookingCalendarEventContent.clientEvent(
            topic: nil,
            expertName: "  ",
            start: start,
            end: end60,
            meetingType: .skypeZoom,
            clientMessage: nil
        )
        #expect(fallback.title == "ClickMe \u{00B7} Session with Expert")
        #expect(fallback.notes == "Skype/Zoom")
    }

    nonisolated private static let offered: [BookingStatus] = [.confirmed, .pendingReschedule, .inProgress]
    nonisolated private static let notOffered: [BookingStatus] = [
        .pendingApproval, .completed, .cancelled, .declined, .missed, .expired, .rescheduled, .unknown
    ]

    @Test("offered for the three booked statuses while the end is after now", arguments: offered)
    func offeredStatuses(status: BookingStatus) {
        #expect(BookingCalendarEventContent.isOffered(status: status, end: start.addingTimeInterval(60), now: start))
    }

    @Test("never offered for any other status, even before the end", arguments: notOffered)
    func notOfferedStatuses(status: BookingStatus) {
        #expect(!BookingCalendarEventContent.isOffered(status: status, end: start.addingTimeInterval(60), now: start))
    }

    @Test("not offered at or after the end, or when the end is unknown", arguments: offered)
    func timeGate(status: BookingStatus) {
        #expect(!BookingCalendarEventContent.isOffered(status: status, end: start, now: start))
        #expect(!BookingCalendarEventContent.isOffered(status: status, end: start.addingTimeInterval(-1), now: start))
        #expect(!BookingCalendarEventContent.isOffered(status: status, end: nil, now: start))
    }
}
