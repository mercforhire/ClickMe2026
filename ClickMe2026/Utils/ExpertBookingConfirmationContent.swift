//
//  ExpertBookingConfirmationContent.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

// MARK: - Expert booking confirmation content

/// The text on the expert's Booking Confirmed screen and in the calendar
/// event it adds (EXP-10, D-13).
///
/// The event is titled `ClickMe · {topic} with {client name}`, the same copy
/// as Android `booking_confirmed_calendar_title`, so both apps put identical
/// events on an expert's calendar. Names and topics are kept exactly as
/// received (emoji, accents, length); only leading and trailing whitespace is
/// trimmed. A blank client reads `Client` and a blank topic reads `Session`.
enum ExpertBookingConfirmationContent {

    /// Shown when the client's name is missing or blank.
    static let clientFallback = "Client"

    /// Shown when the topic is missing or blank.
    static let topicFallback = "Session"

    /// The calendar event title, for example `ClickMe · Career coaching with Jane D.`
    /// (U+00B7 middle dot, one space each side).
    static func calendarTitle(topic: String?, clientName: String?) -> String {
        let topicText = trimmed(topic) ?? topicFallback
        let clientText = trimmed(clientName) ?? clientFallback
        return "ClickMe \u{00B7} \(topicText) with \(clientText)"
    }

    /// The calendar event notes: the meeting type, then a new line and the
    /// client's message only when that message is not blank.
    static func calendarNotes(meetingType: MeetingType, clientMessage: String?) -> String {
        let label = meetingTypeLabel(meetingType)
        guard let message = trimmed(clientMessage) else { return label }
        return label + "\n" + message
    }

    /// `In-App Voice` or `Skype/Zoom`, matching Expert Booking Summary.
    static func meetingTypeLabel(_ meetingType: MeetingType) -> String {
        switch meetingType {
        case .inAppVoice: return "In-App Voice"
        case .skypeZoom: return "Skype/Zoom"
        }
    }

    /// SF Symbol name for the meeting row: `phone` or `video`.
    static func meetingTypeIcon(_ meetingType: MeetingType) -> String {
        switch meetingType {
        case .inAppVoice: return "phone"
        case .skypeZoom: return "video"
        }
    }

    /// `{whole minutes} min` for the window from `start` to `end`.
    static func durationText(start: Date, end: Date) -> String {
        let minutes = Int(end.timeIntervalSince(start) / 60)
        return "\(minutes) min"
    }

    /// The Confirmed body sentence. The client name is already a display
    /// string (fallback applied by the caller).
    static func bodySentence(clientName: String, date: String, time: String) -> String {
        "Your meeting with \(clientName) on \(date), at \(time) has been successfully booked."
    }

    /// Builds the whole Confirmed display model from an accepted request.
    /// Plan 06-05 calls this on accept success.
    ///
    /// - Parameters:
    ///   - clientName: The client's name from the request detail; blank reads `Client`.
    ///   - clientImageURL: The client's photo URL, or `nil` for the person placeholder.
    ///   - topic: The booking topic; blank reads `Session`.
    ///   - clientMessage: The client's request message. Used only in the
    ///     calendar notes, never sent or logged.
    static func confirmation(
        clientName: String?,
        clientImageURL: String?,
        topic: String?,
        start: Date,
        end: Date,
        meetingType: MeetingType,
        clientMessage: String?
    ) -> BookingConfirmation {
        BookingConfirmation(
            clientName: trimmed(clientName) ?? clientFallback,
            clientImageURL: clientImageURL ?? "",
            topic: trimmed(topic) ?? topicFallback,
            date: DateUtil.string(from: start, format: .shortMonthDayYear),
            time: DateUtil.shortTime(start),
            duration: durationText(start: start, end: end),
            meetingTypeLabel: meetingTypeLabel(meetingType),
            meetingTypeIcon: meetingTypeIcon(meetingType),
            calendarTitle: calendarTitle(topic: topic, clientName: clientName),
            calendarNotes: calendarNotes(meetingType: meetingType, clientMessage: clientMessage),
            calendarPayload: BookingCalendarPayload(startDate: start, endDate: end)
        )
    }

    // MARK: - Private

    /// `value` without leading and trailing whitespace; `nil` when it is nil or blank.
    private static func trimmed(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }
}
