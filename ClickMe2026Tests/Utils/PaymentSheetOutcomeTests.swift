//
//  PaymentSheetOutcomeTests.swift
//  ClickMe2026Tests
//
//  PAY-01 / D-01: closing the card sheet (swipe-down, X, tap-outside) cancels
//  the booking even when a saved card is preselected, so no /bookings/confirm
//  call is made and no hold is placed. Only the sheet's Continue control
//  (didCancel false) with a payment option proceeds. The rule is a pure
//  function, so these rows never call the API and do not use APITestFactory.
//

import Testing
@testable import ClickMe2026

@Suite("Payment sheet outcome")
struct PaymentSheetOutcomeTests {

    @Test("closing the sheet with a saved card preselected does not proceed")
    func closedWithSavedCard() {
        #expect(!PaymentSheetOutcome.proceeds(didCancel: true, hasPaymentOption: true))
    }

    @Test("closing the sheet with no payment option does not proceed")
    func closedWithNoOption() {
        #expect(!PaymentSheetOutcome.proceeds(didCancel: true, hasPaymentOption: false))
    }

    @Test("Continue with a payment option proceeds")
    func continueWithOption() {
        #expect(PaymentSheetOutcome.proceeds(didCancel: false, hasPaymentOption: true))
    }

    @Test("Continue with nothing selected does not proceed")
    func continueWithNothingSelected() {
        #expect(!PaymentSheetOutcome.proceeds(didCancel: false, hasPaymentOption: false))
    }
}
