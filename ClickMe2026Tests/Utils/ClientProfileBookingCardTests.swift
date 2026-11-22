//
//  ClientProfileBookingCardTests.swift
//  ClickMe2026Tests
//
//  Pins the amount label on the expert Client Profile history card (BOOK-10).
//  `GET /expert/bookings` sends `consultation_fee.amount` and
//  `earnings_breakdown.net_amount` already divided into major units, so the
//  card must use the major entry point of the shared formatter, and it must
//  show a dash, never a made-up "$0", when it does not know the amount or the
//  currency.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Client profile booking card amount")
struct ClientProfileBookingCardTests {

    @Test("a USD major amount shows full cents with the USD symbol")
    func usdMajorAmount() {
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: 75.0, currency: "USD") == "US$75.00")
    }

    @Test("a CAD major amount shows CA$ and keeps its cents")
    func cadMajorAmount() {
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: 120.5, currency: "CAD") == "CA$120.50")
    }

    @Test("a zero-decimal currency shows no fraction")
    func jpyMajorAmount() {
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: 1200, currency: "JPY") == "¥1200")
    }

    @Test("an unknown amount or currency shows a dash, never $0")
    func unknownAmountOrCurrency() {
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: nil, currency: "USD") == "—")
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: 75.0, currency: nil) == "—")
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: nil, currency: nil) == "—")
    }

    @Test("a non-finite amount shows a dash instead of crashing or printing NaN")
    func nonFiniteAmount() {
        #expect(ClientProfileBookingCard.amountLabel(amountMajor: .nan, currency: "USD") == "—")
    }
}
