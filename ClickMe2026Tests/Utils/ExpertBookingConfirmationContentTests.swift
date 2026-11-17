//
//  ExpertBookingConfirmationContentTests.swift
//  ClickMe2026Tests
//
//  EXP-10 / D-13: the calendar event from an accepted request is titled
//  `ClickMe · {topic} with {client name}`, never with the expert's own name.
//  Dates are asserted against DateUtil itself so the suite passes in any
//  simulator locale.
//

import EventKit
import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Expert booking confirmation content")
struct ExpertBookingConfirmationContentTests {

    private let start = Date(timeIntervalSince1970: 1_795_000_000)
    private var end60: Date { start.addingTimeInterval(60 * 60) }

    // MARK: Title

    @Test("title is ClickMe, middle dot, topic, with, client name")
    func titleExact() {
        let title = ExpertBookingConfirmationContent.calendarTitle(topic: "Career coaching", clientName: "Jane D.")
        #expect(title == "ClickMe \u{00B7} Career coaching with Jane D.")
        #expect(title.unicodeScalars.contains("\u{00B7}"))
    }

    @Test("missing topic and name read Session with Client")
    func titleFallbacks() {
        #expect(ExpertBookingConfirmationContent.calendarTitle(topic: nil, clientName: nil)
            == "ClickMe \u{00B7} Session with Client")
        #expect(ExpertBookingConfirmationContent.calendarTitle(topic: "  ", clientName: "")
            == "ClickMe \u{00B7} Session with Client")
    }

    @Test("title trims surrounding whitespace only")
    func titleTrims() {
        #expect(ExpertBookingConfirmationContent.calendarTitle(topic: " Career coaching ", clientName: " Jane D. ")
            == "ClickMe \u{00B7} Career coaching with Jane D.")
    }

    @Test("emoji, accents and long topics pass through unchanged")
    func titleKeepsInput() {
        let topic = String(repeating: "Long topic ", count: 11) + "end"
        #expect(topic.count > 120)
        let title = ExpertBookingConfirmationContent.calendarTitle(topic: topic, clientName: "Zoë 🎨")
        #expect(title == "ClickMe \u{00B7} \(topic) with Zoë 🎨")
    }

    // MARK: Notes

    @Test("notes are the meeting type alone when there is no message")
    func notesWithoutMessage() {
        #expect(ExpertBookingConfirmationContent.calendarNotes(meetingType: .inAppVoice, clientMessage: nil)
            == "In-App Voice")
        #expect(ExpertBookingConfirmationContent.calendarNotes(meetingType: .skypeZoom, clientMessage: "   ")
            == "Skype/Zoom")
    }

    @Test("notes add the trimmed message on a new line")
    func notesWithMessage() {
        #expect(ExpertBookingConfirmationContent.calendarNotes(meetingType: .inAppVoice, clientMessage: "  Hello there \n")
            == "In-App Voice\nHello there")
    }

    // MARK: Card and body

    @Test("duration reads whole minutes")
    func duration() {
        #expect(ExpertBookingConfirmationContent.durationText(start: start, end: end60) == "60 min")
        #expect(ExpertBookingConfirmationContent.durationText(start: start, end: start.addingTimeInterval(90 * 60))
            == "90 min")
    }

    @Test("body sentence matches the Android copy")
    func body() {
        #expect(ExpertBookingConfirmationContent.bodySentence(
            clientName: "Jane D.", date: "Nov 18, 2026", time: "2:30 PM"
        ) == "Your meeting with Jane D. on Nov 18, 2026, at 2:30 PM has been successfully booked.")
    }

    @Test("confirmation formats date and time through DateUtil and keeps the raw window")
    func confirmationFields() {
        let booking = ExpertBookingConfirmationContent.confirmation(
            clientName: "Jane D.",
            clientImageURL: "https://example.com/jane.jpg",
            topic: "Career coaching",
            start: start,
            end: end60,
            meetingType: .inAppVoice,
            clientMessage: "Hi"
        )
        #expect(booking.date == DateUtil.string(from: start, format: .shortMonthDayYear))
        #expect(booking.time == DateUtil.shortTime(start))
        #expect(booking.clientName == "Jane D.")
        #expect(booking.topic == "Career coaching")
        #expect(booking.clientImageURL == "https://example.com/jane.jpg")
        #expect(booking.duration == "60 min")
        #expect(booking.meetingTypeLabel == "In-App Voice")
        #expect(booking.meetingTypeIcon == "phone")
        #expect(booking.calendarPayload.startDate == start)
        #expect(booking.calendarPayload.endDate == end60)
    }

    @Test("Skype/Zoom uses the video icon")
    func videoIcon() {
        #expect(ExpertBookingConfirmationContent.meetingTypeIcon(.skypeZoom) == "video")
        #expect(ExpertBookingConfirmationContent.meetingTypeIcon(.inAppVoice) == "phone")
    }

    @Test("blank client and topic read Client and Session on the card")
    func confirmationFallbacks() {
        let booking = ExpertBookingConfirmationContent.confirmation(
            clientName: " ",
            clientImageURL: nil,
            topic: nil,
            start: start,
            end: end60,
            meetingType: .skypeZoom,
            clientMessage: nil
        )
        #expect(booking.clientName == "Client")
        #expect(booking.topic == "Session")
        #expect(booking.calendarTitle == "ClickMe \u{00B7} Session with Client")
        #expect(booking.calendarNotes == "Skype/Zoom")
    }

    // MARK: Event

    @Test("the plain event value carries the built title, notes and window")
    func payloadCarriesTitleAndNotes() {
        let booking = ExpertBookingConfirmationContent.confirmation(
            clientName: "Jane D.",
            clientImageURL: nil,
            topic: "Career coaching",
            start: start,
            end: end60,
            meetingType: .inAppVoice,
            clientMessage: "Hello"
        )
        #expect(booking.calendarPayload == BookingCalendarPayload(
            title: "ClickMe \u{00B7} Career coaching with Jane D.",
            notes: "In-App Voice\nHello",
            startDate: start,
            endDate: end60
        ))
        #expect(booking.calendarTitle == booking.calendarPayload.title)
        #expect(booking.calendarNotes == booking.calendarPayload.notes)
    }

    @Test("event carries the built title, notes and window, no location, one 15-minute alert")
    func event() {
        let booking = ExpertBookingConfirmationContent.confirmation(
            clientName: "Jane D.",
            clientImageURL: nil,
            topic: "Career coaching",
            start: start,
            end: end60,
            meetingType: .inAppVoice,
            clientMessage: "Hello"
        )
        let event = CalendarEventEditorSheet.makeEvent(booking.calendarPayload, in: EKEventStore())
        #expect(event.title == "ClickMe \u{00B7} Career coaching with Jane D.")
        #expect(event.notes == "In-App Voice\nHello")
        #expect(event.startDate == start)
        #expect(event.endDate == end60)
        #expect(event.location == nil)
        #expect(event.alarms?.count == 1)
        #expect(event.alarms?.first?.relativeOffset == -900)
    }
}
