//
//  PushEventTests.swift
//  ClickMe2026Tests
//
//  PUSH-01: a push payload is parsed from `route_category`,
//  `route_sub_category`, `target_role` and the entity ids, with Android's
//  `event_type` fallback table (D-05, D-16). The Android-only `category`
//  key is never read. Contract: backend docs/ios/PUSH-ROUTING.md.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("PushEvent parsing")
struct PushEventTests {

    private static let a = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let t = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    private static func parse(_ data: [AnyHashable: Any]) -> PushEvent {
        PushEvent(userInfo: data)
    }

    // MARK: Route keys

    @Test("route_category and route_sub_category are read with the booking id")
    func routeKeys() {
        let event = Self.parse([
            "route_category": "booking",
            "route_sub_category": "requests",
            "booking_id": Self.a.uuidString,
        ])
        #expect(event.category == "booking")
        #expect(event.subCategory == "requests")
        #expect(event.bookingId == Self.a)
    }

    @Test("the Android-only category and sub_category keys are never read")
    func androidKeysIgnored() {
        let event = Self.parse(["category": "booking", "sub_category": "requests"])
        #expect(event.category == nil)
        #expect(event.subCategory == nil)
    }

    @Test("route_category wins over a category key")
    func routeCategoryWinsOverCategory() {
        let event = Self.parse(["category": "payout", "route_category": "booking"])
        #expect(event.category == "booking")
    }

    // MARK: event_type fallback

    @Test("an empty route_category falls back to event_type for chat")
    func chatFallback() {
        let event = Self.parse([
            "route_category": "",
            "event_type": "NEW_MESSAGE",
            "thread_id": Self.t.uuidString,
        ])
        #expect(event.category == "message")
        #expect(event.subCategory == "new_message")
        #expect(event.threadId == Self.t)
    }

    @Test("every event_type in the fallback table maps as Android does", arguments: [
        (eventType: "NEW_MESSAGE", category: "message", subCategory: "new_message"),
        (eventType: "NEW_BOOKING_REQUEST", category: "booking", subCategory: "requests"),
        (eventType: "BOOKING_REQUEST", category: "booking", subCategory: "requests"),
        (eventType: "REQUEST_CREATED", category: "booking", subCategory: "requests"),
        (eventType: "BOOKING_CONFIRMED", category: "booking", subCategory: "confirmations"),
        (eventType: "BOOKING_DECLINED", category: "booking", subCategory: "declines"),
        (eventType: "BOOKING_CANCELLED", category: "booking", subCategory: "cancellations"),
        (eventType: "BOOKING_RESCHEDULED", category: "booking", subCategory: "reschedules"),
        (eventType: "BOOKING_EXPIRED", category: "booking", subCategory: "expirations"),
        (eventType: "BOOKING_COMPLETED", category: "session", subCategory: "ended"),
        (eventType: "REVIEW_SUBMITTED", category: "review", subCategory: "received"),
        (eventType: "REFUND_ISSUED", category: "booking", subCategory: "refunds"),
        (eventType: "PAYMENT_ACTION_REQUIRED", category: "booking", subCategory: "payment_actions"),
        (eventType: "PAYOUT_PAID", category: "payout", subCategory: "paid"),
        (eventType: "PAYOUT_FAILED", category: "payout", subCategory: "failed"),
        (eventType: "KYC_ACTION_REQUIRED", category: "payout", subCategory: "kyc_action"),
        (eventType: "DISPUTE_CREATED", category: "payout", subCategory: "dispute"),
        (eventType: "PASSWORD_CHANGED", category: "account", subCategory: "password_changed"),
        (eventType: "DELETION_REQUESTED", category: "account", subCategory: "deletion_requested"),
    ])
    func fallbackTable(_ row: (eventType: String, category: String, subCategory: String)) {
        let event = Self.parse(["event_type": row.eventType])
        #expect(event.category == row.category)
        #expect(event.subCategory == row.subCategory)
    }

    @Test("event_type matches case-insensitively")
    func fallbackIsCaseInsensitive() {
        let event = Self.parse(["event_type": "new_message"])
        #expect(event.category == "message")
        #expect(event.subCategory == "new_message")
    }

    @Test("route_category wins over event_type when both are present")
    func routeCategoryWinsOverEventType() {
        let event = Self.parse(["route_category": "session", "event_type": "NEW_MESSAGE"])
        #expect(event.category == "session")
    }

    @Test("an unknown event_type with no route_category gives no category")
    func unknownEventType() {
        let event = Self.parse(["event_type": "SOMETHING_ELSE", "booking_id": Self.a.uuidString])
        #expect(event.category == nil)
        #expect(event.subCategory == nil)
    }

    // MARK: Payload shape

    @Test("a nested data dictionary wins over root keys")
    func nestedDataWins() {
        let event = Self.parse([
            "data": ["route_category": "review"],
            "route_category": "booking",
        ])
        #expect(event.category == "review")
    }

    @Test("category and sub-category are trimmed and lowercased; an empty sub-category is nil")
    func normalization() {
        let event = Self.parse(["route_category": "  Booking ", "route_sub_category": " Requests "])
        #expect(event.category == "booking")
        #expect(event.subCategory == "requests")

        let emptySub = Self.parse(["route_category": "booking", "route_sub_category": ""])
        #expect(emptySub.subCategory == nil)
    }

    @Test("an empty payload parses to nothing")
    func emptyPayload() {
        let event = Self.parse([:])
        #expect(event.category == nil)
        #expect(event.subCategory == nil)
        #expect(event.bookingId == nil)
        #expect(event.threadId == nil)
        #expect(event.reviewId == nil)
        #expect(event.payoutId == nil)
        #expect(event.targetRole == nil)
    }

    // MARK: target_role

    @Test("target_role reads client and expert only")
    func targetRole() {
        #expect(Self.parse(["target_role": "client"]).targetRole == .client)
        #expect(Self.parse(["target_role": "expert"]).targetRole == .expert)
        #expect(Self.parse(["target_role": " Expert "]).targetRole == .expert)
        #expect(Self.parse(["target_role": "admin"]).targetRole == nil)
        #expect(Self.parse(["route_category": "booking"]).targetRole == nil)
    }

    // MARK: Ids

    @Test("ids are read only when they parse as UUIDs")
    func ids() {
        #expect(Self.parse(["booking_id": "not-a-uuid"]).bookingId == nil)
        #expect(Self.parse(["booking_id": ""]).bookingId == nil)

        let upper = Self.parse(["booking_id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"])
        #expect(upper.bookingId == UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"))

        let all = Self.parse([
            "booking_id": Self.a.uuidString,
            "thread_id": Self.t.uuidString,
            "review_id": Self.a.uuidString,
            "payout_id": Self.t.uuidString,
        ])
        #expect(all.bookingId == Self.a)
        #expect(all.threadId == Self.t)
        #expect(all.reviewId == Self.a)
        #expect(all.payoutId == Self.t)
    }
}
