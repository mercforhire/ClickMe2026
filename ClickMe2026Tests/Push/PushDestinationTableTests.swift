//
//  PushDestinationTableTests.swift
//  ClickMe2026Tests
//
//  PUSH-01, PUSH-03, BOOK-15: one table maps a notification's category,
//  sub-category and ids to a destination, for push taps and notifications-list
//  rows alike. Contract: backend docs/ios/PUSH-ROUTING.md.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Push destination table")
struct PushDestinationTableTests {

    private static let a = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let t = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    private static func route(
        _ category: String?,
        _ subCategory: String?,
        booking: UUID? = nil,
        thread: UUID? = nil
    ) -> PushDestination? {
        PushRouter.destination(
            category: category,
            subCategory: subCategory,
            bookingId: booking,
            threadId: thread
        )
    }

    // MARK: Booking

    @Test("booking/requests opens that request when a booking id is present, else the hub")
    func requests() {
        #expect(Self.route("booking", "requests", booking: Self.a) == .incomingRequest(bookingId: Self.a))
        #expect(Self.route("booking", "requests") == .incomingRequests)
    }

    @Test("confirmations, reschedules and payment_actions open the booking detail", arguments: [
        "confirmations", "reschedules", "payment_actions"
    ])
    func bookingDetailRows(_ sub: String) {
        #expect(Self.route("booking", sub, booking: Self.a) == .bookingDetail(bookingId: Self.a))
    }

    @Test("payment_actions with no booking id maps to nothing")
    func paymentActionsNoId() {
        #expect(Self.route("booking", "payment_actions") == nil)
    }

    @Test("terminal booking rows open the booking summary", arguments: [
        "declines", "cancellations", "expirations", "refunds"
    ])
    func terminalRows(_ sub: String) {
        #expect(Self.route("booking", sub, booking: Self.a) == .bookingSummary(bookingId: Self.a))
        #expect(Self.route("booking", sub) == nil)
    }

    // MARK: Session

    @Test("session rows")
    func session() {
        #expect(Self.route("session", "ended", booking: Self.a) == .leaveReview(bookingId: Self.a))
        #expect(Self.route("session", "reminder", booking: Self.a) == .bookingDetail(bookingId: Self.a))
        #expect(Self.route("session", "no_show", booking: Self.a) == .bookingDetail(bookingId: Self.a))
        #expect(Self.route("session", "reminder") == nil)
    }

    // MARK: Message

    @Test("message/new_message opens the thread")
    func message() {
        #expect(Self.route("message", "new_message", thread: Self.t) == .chatThread(threadId: Self.t))
        #expect(Self.route("message", "new_message") == nil)
    }

    // MARK: Review

    @Test("review rows")
    func review() {
        #expect(Self.route("review", "nudge", booking: Self.a) == .leaveReview(bookingId: Self.a))
        #expect(Self.route("review", "received", booking: Self.a) == .bookingDetail(bookingId: Self.a))
        #expect(Self.route("review", "received") == nil)
    }

    // MARK: Payout and account

    @Test("payout rows")
    func payout() {
        #expect(Self.route("payout", "kyc_action") == .kycOnboarding)
        for sub in ["paid", "failed", "dispute"] {
            #expect(Self.route("payout", sub) == .payouts)
        }
    }

    @Test("account rows open account security", arguments: ["password_changed", "deletion_requested"])
    func account(_ sub: String) {
        #expect(Self.route("account", sub) == .accountSecurity)
    }

    // MARK: Normalization and unknowns

    @Test("category and sub-category match case-insensitively")
    func caseInsensitive() {
        #expect(Self.route("BOOKING", "Requests", booking: Self.a) == .incomingRequest(bookingId: Self.a))
        #expect(Self.route(" Booking ", " DECLINES ", booking: Self.a) == .bookingSummary(bookingId: Self.a))
    }

    @Test("an empty, missing or unknown category maps to no destination")
    func unknown() {
        #expect(Self.route(nil, "requests", booking: Self.a) == nil)
        #expect(Self.route("", "requests", booking: Self.a) == nil)
        #expect(Self.route("unknown", nil, booking: Self.a, thread: Self.t) == nil)
    }
}
