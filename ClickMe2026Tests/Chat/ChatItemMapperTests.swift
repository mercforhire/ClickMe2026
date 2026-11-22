//
//  ChatItemMapperTests.swift
//  ClickMe2026Tests
//
//  IN-03: `event_data` comes from the backend, so a number outside the `Int` range must
//  read as missing instead of crashing the mapping of a whole thread page.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat item mapper")
@MainActor
struct ChatItemMapperTests {

    private static let identity = ChatItemMapper.Identity(
        myUserId: UUID(),
        myName: "Me",
        myAvatarURL: "",
        peerName: "Peer",
        peerAvatarURL: ""
    )

    private static func mappedEvent(durationMins: JSONValue?) -> BookingEvent? {
        let item = ChatMessageItem(
            id: UUID(),
            threadId: UUID(),
            senderId: nil,
            sender: nil,
            type: .event,
            content: nil,
            status: .sent,
            clientMsgId: nil,
            eventType: .bookingConfirmed,
            eventData: durationMins.map { .object(["duration_mins": $0]) },
            createdAt: Date()
        )
        guard case let .systemEvent(event) = ChatItemMapper.chatItem(from: item, identity: identity) else {
            return nil
        }
        return event
    }

    private static func mappedEvent(
        _ kind: MessageEventType,
        eventData: [String: JSONValue]?
    ) -> BookingEvent? {
        let item = ChatMessageItem(
            id: UUID(),
            threadId: UUID(),
            senderId: nil,
            sender: nil,
            type: .event,
            content: nil,
            status: .sent,
            clientMsgId: nil,
            eventType: kind,
            eventData: eventData.map { .object($0) },
            createdAt: Date()
        )
        guard case let .systemEvent(event) = ChatItemMapper.chatItem(from: item, identity: identity) else {
            return nil
        }
        return event
    }

    @Test("a cancel reason is trimmed and labelled by reason_by")
    func cancelReasonIsLabelledByWhoGaveIt() {
        let client = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("  Running late  "), "reason_by": .string("client")]
        )
        #expect(client?.reasonCaption == "Reason from the client: Running late")
        let expert = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("Running late"), "reason_by": .string("expert")]
        )
        #expect(expert?.reasonCaption == "Reason from the expert: Running late")
        let plain = Self.mappedEvent(.bookingCancelled, eventData: ["reason_text": .string("Running late")])
        #expect(plain?.reasonCaption == "Reason: Running late")
        let unknown = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("Running late"), "reason_by": .string("admin")]
        )
        #expect(unknown?.reasonCaption == "Reason: Running late")
    }

    @Test("a whitespace-only reason shows no caption")
    func blankReasonShowsNothing() {
        let event = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("   "), "reason_by": .string("client")]
        )
        #expect(event?.reasonCaption == nil)
    }

    @Test("a cancelled event without the new keys maps as before")
    func eventWithoutReasonKeysIsUnchanged() {
        let event = Self.mappedEvent(.bookingCancelled, eventData: ["duration_mins": .int(30)])
        #expect(event?.reasonCaption == nil)
        #expect(event?.reasonCodeLabel == nil)
        #expect(event?.title == "Booking Cancelled")
        #expect(event?.isTerminal == true)
        #expect(event?.durationMins == 30)
    }

    @Test("a reschedule proposal note is labelled Note, by who sent it")
    func rescheduleNoteIsLabelled() {
        let expert = Self.mappedEvent(
            .bookingRescheduled,
            eventData: ["reason_text": .string("Can we do 3pm?"), "reason_by": .string("expert")]
        )
        #expect(expert?.reasonCaption == "Note from the expert: Can we do 3pm?")
        let client = Self.mappedEvent(
            .bookingRescheduled,
            eventData: ["reason_text": .string("Can we do 3pm?"), "reason_by": .string("client")]
        )
        #expect(client?.reasonCaption == "Note from the client: Can we do 3pm?")
        let plain = Self.mappedEvent(.bookingRescheduled, eventData: ["reason_text": .string("Can we do 3pm?")])
        #expect(plain?.reasonCaption == "Note: Can we do 3pm?")
    }

    @Test("a request decline falls back to decline_reason_text and is the expert's")
    func requestDeclineFallsBackToDeclineReasonText() {
        let fallback = Self.mappedEvent(.bookingDeclined, eventData: ["decline_reason_text": .string("Fully booked")])
        #expect(fallback?.reasonCaption == "Reason from the expert: Fully booked")
        let both = Self.mappedEvent(
            .bookingDeclined,
            eventData: ["reason_text": .string("Primary"), "decline_reason_text": .string("Fallback")]
        )
        #expect(both?.reasonCaption == "Reason from the expert: Primary")
        let blankPrimary = Self.mappedEvent(
            .bookingDeclined,
            eventData: ["reason_text": .string("  "), "decline_reason_text": .string("Fallback")]
        )
        #expect(blankPrimary?.reasonCaption == "Reason from the expert: Fallback")
    }

    @Test("a known decline_reason_code adds its label; an unknown one adds nothing, never the raw code")
    func declineCodeLabel() {
        let known = Self.mappedEvent(.bookingDeclined, eventData: ["decline_reason_code": .string("UNAVAILABLE")])
        #expect(known?.reasonCodeLabel == DeclineNote.reasonLine(for: "UNAVAILABLE"))
        #expect(known?.reasonCodeLabel != nil)
        let unknown = Self.mappedEvent(.bookingDeclined, eventData: ["decline_reason_code": .string("MYSTERY_CODE")])
        #expect(unknown?.reasonCodeLabel == nil)
        #expect(unknown?.reasonCaption == nil)
    }

    @Test("reschedule_decline makes the row Reschedule Declined and not terminal")
    func rescheduleDeclineMarker() {
        let event = Self.mappedEvent(
            .bookingDeclined,
            eventData: [
                "reschedule_decline": .bool(true),
                "reason_text": .string("Too soon"),
                "reason_by": .string("client"),
                "decline_reason_text": .string("ignored"),
                "decline_reason_code": .string("UNAVAILABLE")
            ]
        )
        #expect(event?.title == "Reschedule Declined")
        #expect(event?.isTerminal == false)
        #expect(event?.icon == "xmark.square")
        #expect(event?.reasonCaption == "Reason from the client: Too soon")
        #expect(event?.reasonCodeLabel == nil)
        let plain = Self.mappedEvent(
            .bookingDeclined,
            eventData: ["reschedule_decline": .bool(true), "reason_text": .string("Too soon")]
        )
        #expect(plain?.reasonCaption == "Reason: Too soon")
    }

    @Test("a decline without the marker stays Booking Declined and terminal")
    func declineWithoutMarker() {
        let event = Self.mappedEvent(.bookingDeclined, eventData: ["reschedule_decline": .bool(false)])
        #expect(event?.title == "Booking Declined")
        #expect(event?.isTerminal == true)
    }

    @Test("duration_mins reads from an int, a numeric string and a whole double")
    func readsWholeNumbers() {
        #expect(Self.mappedEvent(durationMins: .int(30))?.durationMins == 30)
        #expect(Self.mappedEvent(durationMins: .string("45"))?.durationMins == 45)
        #expect(Self.mappedEvent(durationMins: .double(60))?.durationMins == 60)
    }

    @Test("duration_mins reads as nil for a double that is out of range, fractional or not a number")
    func rejectsUnrepresentableDoubles() {
        #expect(Self.mappedEvent(durationMins: .double(1e30))?.durationMins == nil)
        #expect(Self.mappedEvent(durationMins: .double(30.5))?.durationMins == nil)
        #expect(Self.mappedEvent(durationMins: .double(.nan))?.durationMins == nil)
        #expect(Self.mappedEvent(durationMins: .double(.infinity))?.durationMins == nil)
        // The row itself still maps.
        #expect(Self.mappedEvent(durationMins: .double(1e30)) != nil)
    }
}
