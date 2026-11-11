//
//  CancelToastMessageTests.swift
//  ClickMe2026Tests
//
//  BOOK-08 (D-06): the post-cancel toast follows the server's refund_amount and
//  the case the client confirmed under. A server 0 is never worded "no refund"
//  except for a charge cancelled inside 24 hours.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Cancel toast message")
struct CancelToastMessageTests {

    private func text(_ refund: Double, _ confirmedCase: CancelRefundPreview.Case, currency: String = "CAD") -> String {
        CancelToastMessage.text(serverRefundMajor: refund, currency: currency, confirmedCase: confirmedCase)
    }

    @Test("a refund above zero names the amount under any case")
    func refundAboveZero() {
        let expected = "Booking cancelled. CA$45.00 will be refunded to your card."
        #expect(text(45.0, .free) == expected)
        #expect(text(45.0, .liveHold(amount: "CA$45.00")) == expected)
        #expect(text(45.0, .chargedRefundable(amount: "CA$45.00")) == expected)
        #expect(text(45.0, .chargedNotRefundable(zero: "CA$0.00")) == expected)
        #expect(text(45.0, .notChargedYet) == expected)
        #expect(text(45.0, .amountUnknown) == expected)
    }

    @Test("a zero refund on a free booking or an unknown case is plain")
    func zeroFreeAndUnknown() {
        #expect(text(0, .free) == "Booking cancelled.")
        #expect(text(0, .amountUnknown) == "Booking cancelled.")
    }

    @Test("a zero refund on a live hold says the hold is being released")
    func zeroLiveHold() {
        #expect(
            text(0, .liveHold(amount: "CA$45.00"))
                == "Booking cancelled. The CA$45.00 hold on your card is being released."
        )
    }

    @Test("a zero refund on a refundable charge says the refund is being processed, not that none applies")
    func zeroChargedRefundable() {
        let message = text(0, .chargedRefundable(amount: "CA$45.00"))
        #expect(message == "Booking cancelled. Your CA$45.00 refund is being processed.")
        #expect(!message.contains("No refund"))
    }

    @Test("only a charge inside 24 hours reads as no refund applies")
    func zeroChargedNotRefundable() {
        #expect(
            text(0, .chargedNotRefundable(zero: "CA$0.00"))
                == "Booking cancelled. No refund applies because the session was within 24 hours."
        )
    }

    @Test("a zero refund on a never-charged booking says so")
    func zeroNotCharged() {
        #expect(text(0, .notChargedYet) == "Booking cancelled. You weren't charged.")
    }

    @Test("no case other than charged-inside-24-hours ever says no refund applies")
    func noRefundWordingIsExclusive() {
        let others: [CancelRefundPreview.Case] = [
            .free, .liveHold(amount: "CA$45.00"), .chargedRefundable(amount: "CA$45.00"),
            .notChargedYet, .amountUnknown,
        ]
        for confirmedCase in others {
            #expect(!text(0, confirmedCase).contains("No refund applies"))
        }
    }

    @Test("an amount Money cannot format falls back to plain")
    func unformattableAmount() {
        #expect(text(.infinity, .chargedRefundable(amount: "CA$45.00")) == "Booking cancelled.")
    }
}
