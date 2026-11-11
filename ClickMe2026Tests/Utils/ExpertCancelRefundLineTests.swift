//
//  ExpertCancelRefundLineTests.swift
//  ClickMe2026Tests
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ClickMe2026

/// EXP-11: the expert cancel sheet's client-money line (D-07, D-14, D-16).
@MainActor
@Suite("Expert cancel refund line")
struct ExpertCancelRefundLineTests {

    private static let hold = Date(timeIntervalSince1970: 1_800_000_000)

    private static func line(
        amount: Double = 45,
        currency: String = "CAD",
        hold: Date? = nil,
        actionRequired: Bool? = false,
        notCharged: Bool? = false
    ) -> ExpertCancelRefundLine {
        ExpertCancelRefundLine.make(
            consultationAmountMajor: amount,
            currency: currency,
            authorizationExpiresAt: hold,
            paymentActionRequired: actionRequired,
            paymentNotCharged: notCharged
        )
    }

    // MARK: Free

    @Test("a free booking has no money line whatever the keys read")
    func freeBooking() {
        #expect(Self.line(amount: 0) == .none)
        #expect(Self.line(amount: 0, hold: Self.hold) == .none)
        #expect(Self.line(amount: 0, actionRequired: nil, notCharged: nil) == .none)
        #expect(Self.line(amount: 0).text == nil)
        #expect(Self.line(amount: 0).showsFootnote == false)
    }

    // MARK: Fail closed (D-14)

    @Test("a payload without either key shows no money line, live hold included")
    func bothKeysAbsent() {
        #expect(Self.line(actionRequired: nil, notCharged: nil) == .none)
        #expect(Self.line(hold: Self.hold, actionRequired: nil, notCharged: nil) == .none)
    }

    @Test("either key absent alone shows no money line")
    func oneKeyAbsent() {
        #expect(Self.line(actionRequired: false, notCharged: nil) == .none)
        #expect(Self.line(actionRequired: nil, notCharged: false) == .none)
        #expect(Self.line(hold: Self.hold, actionRequired: false, notCharged: nil) == .none)
        #expect(Self.line(hold: Self.hold, actionRequired: nil, notCharged: false) == .none)
    }

    @Test("card authentication pending shows no money line")
    func actionRequired() {
        #expect(Self.line(actionRequired: true, notCharged: false) == .none)
        #expect(Self.line(actionRequired: true, notCharged: true) == .none)
        #expect(Self.line(hold: Self.hold, actionRequired: true, notCharged: false) == .none)
    }

    // MARK: Never charged (D-16)

    @Test("a booking with no PaymentIntent shows no money line, with or without a stale hold date")
    func notCharged() {
        #expect(Self.line(actionRequired: false, notCharged: true) == .none)
        #expect(Self.line(hold: Self.hold, actionRequired: false, notCharged: true) == .none)
        #expect(Self.line(actionRequired: false, notCharged: true).showsFootnote == false)
    }

    // MARK: D-07 lines

    @Test("a live hold reads as released, with the lock icon and no footnote")
    func liveHold() {
        let line = Self.line(hold: Self.hold)
        #expect(line == .holdReleased(amount: "CA$45.00"))
        #expect(line.text == "The client's CA$45.00 hold will be released.")
        #expect(line.emphasis == "CA$45.00")
        #expect(line.iconName == "lock.fill")
        #expect(line.showsFootnote == false)
    }

    @Test("a paid booking without a hold reads as a full refund, with the footnote")
    func fullRefund() {
        let line = Self.line()
        #expect(line == .fullRefund(amount: "CA$45.00"))
        #expect(line.text == "The client will get a full refund of CA$45.00")
        #expect(line.emphasis == "CA$45.00")
        #expect(line.iconName == "creditcard")
        #expect(line.showsFootnote == true)
    }

    @Test("fractional amounts keep both minor digits")
    func fractionalAmount() {
        #expect(Self.line(amount: 12.5).text == "The client will get a full refund of CA$12.50")
    }

    @Test("an amount Money cannot format falls back to the plain sentences")
    func unformattable() {
        let refund = Self.line(amount: .infinity)
        #expect(refund == .fullRefund(amount: nil))
        #expect(refund.text == "The client will get a full refund.")
        #expect(refund.emphasis == nil)
        #expect(refund.showsFootnote == true)

        let release = Self.line(amount: .infinity, hold: Self.hold)
        #expect(release.text == "The client's hold will be released.")
    }

    @Test("the none case has no text, emphasis, icon or footnote")
    func noneCase() {
        let none = ExpertCancelRefundLine.none
        #expect(none.text == nil)
        #expect(none.emphasis == nil)
        #expect(none.iconName == nil)
        #expect(none.showsFootnote == false)
    }
}

// MARK: - Decoded expert details (D-14, D-16 end to end)

/// `GET /expert/bookings/:id/details` carries `payment_action_required` and
/// `payment_not_charged` (backend 65bb2ed). Each is optional so a payload
/// without it still decodes, and the rule then fails closed.
@MainActor
@Suite("Expert details payment keys")
struct ExpertDetailPaymentKeysTests {

    /// Configured like `NetworkService`'s decoder for the keys this fixture
    /// needs (snake_case keys, ISO-8601 dates).
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// A minimal details payload with every required field; `extra` is
    /// appended as further members (for example `,"payment_not_charged":true`).
    private static func decode(amount: Double = 45, extra: String) throws -> ExpertBookingDetail {
        let json = """
        {"booking_id":"11111111-1111-4111-8111-111111111111",
         "status":{"label":"Confirmed","code":"confirmed","color_accent":"green"},
         "client":{"id":"22222222-2222-4222-8222-222222222222","name":"Sam","avatar_url":null},
         "session":{"topic_title":"Algorithms",
                    "consultation_fee":{"amount":\(amount),"currency":"CAD","label":"CA$45.00 / session"},
                    "schedule":{"start_time":"2027-01-15T18:00:00Z","end_time":"2027-01-15T18:30:00Z"},
                    "meeting_type":"in_app_voice"},
         "preparation_notes":{"text":null},
         "actions":{"can_join":false,"can_reschedule":true,"can_cancel":true,"can_message":true}\(extra)}
        """
        return try makeDecoder().decode(ExpertBookingDetail.self, from: Data(json.utf8))
    }

    private static func line(_ detail: ExpertBookingDetail) -> ExpertCancelRefundLine {
        ExpertCancelRefundLine.make(
            consultationAmountMajor: detail.session.consultationFee.amount,
            currency: detail.session.consultationFee.currency,
            authorizationExpiresAt: detail.authorizationExpiresAt,
            paymentActionRequired: detail.paymentActionRequired,
            paymentNotCharged: detail.paymentNotCharged
        )
    }

    private static let holdMember = #","authorization_expires_at":"2027-01-10T18:00:00Z""#

    // MARK: Decoding

    @Test("payment_action_required decodes true, false and absent")
    func decodesActionRequired() throws {
        #expect(try Self.decode(extra: #","payment_action_required":true"#).paymentActionRequired == true)
        #expect(try Self.decode(extra: #","payment_action_required":false"#).paymentActionRequired == false)
        #expect(try Self.decode(extra: "").paymentActionRequired == nil)
    }

    @Test("payment_not_charged decodes true, false and absent")
    func decodesNotCharged() throws {
        #expect(try Self.decode(extra: #","payment_not_charged":true"#).paymentNotCharged == true)
        #expect(try Self.decode(extra: #","payment_not_charged":false"#).paymentNotCharged == false)
        #expect(try Self.decode(extra: "").paymentNotCharged == nil)
    }

    @Test("each key decodes independently of the other")
    func keysAreIndependent() throws {
        let detail = try Self.decode(extra: #","payment_action_required":true"#)
        #expect(detail.paymentActionRequired == true)
        #expect(detail.paymentNotCharged == nil)
    }

    // MARK: End to end through the rule

    @Test("a payload without either key gives no money line")
    func absentKeysFailClosed() throws {
        #expect(Self.line(try Self.decode(extra: "")) == .none)
        #expect(Self.line(try Self.decode(extra: Self.holdMember)) == .none)
    }

    @Test("a converted long-lead booking gives no money line (D-16)")
    func convertedLongLead() throws {
        let detail = try Self.decode(
            extra: #","payment_action_required":false,"payment_not_charged":true,"authorization_expires_at":null"#
        )
        #expect(Self.line(detail) == .none)
    }

    @Test("both keys false give a full refund, or a release with a live hold")
    func bothFalse() throws {
        let keys = #","payment_action_required":false,"payment_not_charged":false"#
        #expect(Self.line(try Self.decode(extra: keys)) == .fullRefund(amount: "CA$45.00"))
        #expect(Self.line(try Self.decode(extra: keys + Self.holdMember)) == .holdReleased(amount: "CA$45.00"))
    }

    @Test("a card-authentication-pending booking gives no money line (D-14)")
    func scaPending() throws {
        let detail = try Self.decode(extra: #","payment_action_required":true,"payment_not_charged":true"#)
        #expect(Self.line(detail) == .none)
    }
}
