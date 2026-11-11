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
