//
//  BookingCalendarEventContent.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

// MARK: - Booking calendar event content

/// The calendar event text and the rule for when Add to Calendar is offered,
/// shared by Booking Confirmed, the expert Booking Summary and the client
/// Upcoming Booking screen (EXP-10, D-13, G-06-1-summary-calendar).
///
/// The title is `ClickMe · {topic} with {name}` (U+00B7 middle dot), the same
/// copy as Android `booking_confirmed_calendar_title`, so every screen and both
/// apps put identical events on a calendar. Names and topics are kept exactly
/// as received (emoji, accents, length); only leading and trailing whitespace
/// is trimmed. A blank topic reads `Session`.
enum BookingCalendarEventContent {

    /// Shown when the topic is missing or blank.
    static let topicFallback = "Session"

    /// Shown in place of a missing or blank client name (expert side).
    static let clientFallback = "Client"

    /// The calendar event title, for example `ClickMe · Career coaching with Jane D.`
    ///
    /// - Parameters:
    ///   - topic: The booking topic; blank reads `Session`.
    ///   - counterpartName: The other party's name; blank reads `counterpartFallback`.
    ///   - counterpartFallback: `Client` on the expert side, `Expert` on the client side.
    static func title(topic: String?, counterpartName: String?, counterpartFallback: String) -> String {
        let topicText = trimmed(topic) ?? topicFallback
        let nameText = trimmed(counterpartName) ?? counterpartFallback
        return "ClickMe \u{00B7} \(topicText) with \(nameText)"
    }

    /// The calendar event notes: the meeting type, then a new line and the
    /// message only when that message is not blank.
    static func notes(meetingType: MeetingType, message: String?) -> String {
        let label = ExpertBookingConfirmationContent.meetingTypeLabel(meetingType)
        guard let text = trimmed(message) else { return label }
        return label + "\n" + text
    }

    /// The event the expert adds for a booking with a client. Booking Confirmed
    /// and the expert Booking Summary both build it here, so the two events are
    /// identical for the same booking.
    ///
    /// - Parameters:
    ///   - topic: The booking topic; blank reads `Session`.
    ///   - clientName: The client's name; blank reads `Client`.
    ///   - clientMessage: The client's request message, used only in the notes.
    static func expertEvent(
        topic: String?,
        clientName: String?,
        start: Date,
        end: Date,
        meetingType: MeetingType,
        clientMessage: String?
    ) -> BookingCalendarPayload {
        BookingCalendarPayload(
            title: title(topic: topic, counterpartName: clientName, counterpartFallback: clientFallback),
            notes: notes(meetingType: meetingType, message: clientMessage),
            startDate: start,
            endDate: end
        )
    }

    /// Shown in place of a missing or blank expert name (client side).
    static let expertFallback = "Expert"

    /// The event a client adds for a booking with an expert, titled
    /// `ClickMe · {topic} with {expert name}`. Plan 06-14 calls it from the
    /// client Upcoming Booking screen.
    ///
    /// - Parameters:
    ///   - topic: The booking topic; blank reads `Session`.
    ///   - expertName: The expert's name; blank reads `Expert`.
    ///   - clientMessage: The client's own note on the booking, used only in the notes.
    static func clientEvent(
        topic: String?,
        expertName: String?,
        start: Date,
        end: Date,
        meetingType: MeetingType,
        clientMessage: String?
    ) -> BookingCalendarPayload {
        BookingCalendarPayload(
            title: title(topic: topic, counterpartName: expertName, counterpartFallback: expertFallback),
            notes: notes(meetingType: meetingType, message: clientMessage),
            startDate: start,
            endDate: end
        )
    }

    // MARK: - Offer rule

    /// Statuses for which Add to Calendar is offered: booked and not over, the
    /// same set as `ExpertJoinVisibility.alwaysShownStatuses`. `pending_approval`
    /// is not booked yet and may be declined or expire, so it is left out.
    static let offeredStatuses: Set<BookingStatus> = [.confirmed, .pendingReschedule, .inProgress]

    /// True when Add to Calendar is offered at `now`: an offered status whose
    /// known end is strictly after `now`. Callers pass the 60 s timeline date.
    /// A display gate only.
    ///
    /// - Parameters:
    ///   - status: The booking's wire status.
    ///   - end: The scheduled end, or `nil` when unknown (never offered).
    ///   - now: The moment to evaluate.
    static func isOffered(status: BookingStatus, end: Date?, now: Date) -> Bool {
        guard offeredStatuses.contains(status), let end else { return false }
        return end > now
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
