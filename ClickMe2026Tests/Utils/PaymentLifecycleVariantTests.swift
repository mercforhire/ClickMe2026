//
//  PaymentLifecycleVariantTests.swift
//  ClickMe2026Tests
//
//  PAY-03: Request Sent's payment card describes what the booking's payment
//  data supports. A live hold, a scheduled charge and a taken payment each get
//  their own copy; everything else (free, held with no live expiry, none on a
//  booking that will not be charged, refunded, unknown) hides the card.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Payment lifecycle variant")
struct PaymentLifecycleVariantTests {

    private let expiry = Date(timeIntervalSince1970: 4_070_944_800)

    private func choose(
        isFree: Bool = false,
        status: String? = "confirmed",
        payment: String?,
        expiresAt: Date? = nil
    ) -> PaymentLifecycleVariant? {
        PaymentLifecycleVariant.choose(
            isFree: isFree,
            bookingStatus: status,
            paymentStatus: payment,
            authorizationExpiresAt: expiresAt
        )
    }

    // MARK: Free

    @Test("a free topic gets no card for any booking or payment status", arguments: [
        "none", "held", "captured", "refunded", ""
    ])
    func freeHidesCard(payment: String) {
        #expect(choose(isFree: true, payment: payment, expiresAt: expiry) == nil)
        #expect(choose(isFree: true, status: "pending_approval", payment: payment) == nil)
    }

    // MARK: Variant A

    @Test("held with a live authorization expiry is the live hold")
    func heldWithExpiryIsLiveHold() {
        #expect(choose(payment: "held", expiresAt: expiry) == .liveHold)
    }

    @Test("held with a live expiry is a live hold on every active status")
    func liveHoldOnActiveStatuses() {
        for status in ["pending_approval", "pending_reschedule", "confirmed", "in_progress"] {
            #expect(choose(status: status, payment: "held", expiresAt: expiry) == .liveHold)
        }
    }

    // MARK: Variant B

    @Test("none on a pending or confirmed booking is a scheduled charge", arguments: [
        "pending_approval", "pending_reschedule", "confirmed"
    ])
    func noneOnScheduledStatusIsChargeScheduled(status: String) {
        #expect(choose(status: status, payment: "none") == .chargeScheduled)
    }

    @Test("none on a booking that will not be charged hides the card", arguments: [
        "cancelled", "declined", "expired", "missed", "completed", "in_progress", "rescheduled", ""
    ])
    func noneOnOtherStatusHidesCard(status: String) {
        #expect(choose(status: status, payment: "none") == nil)
    }

    @Test("none with a missing booking status hides the card")
    func noneWithMissingStatusHidesCard() {
        #expect(choose(status: nil, payment: "none") == nil)
    }

    // MARK: Variant C

    @Test("captured is already charged")
    func capturedIsAlreadyCharged() {
        #expect(choose(status: "completed", payment: "captured") == .alreadyCharged)
    }

    // MARK: Fail closed

    @Test("held with no authorization expiry hides the card, never 'charged'")
    func heldWithoutExpiryHidesCard() {
        #expect(choose(payment: "held", expiresAt: nil) == nil)
        for status in ["pending_approval", "pending_reschedule", "confirmed", "in_progress"] {
            #expect(choose(status: status, payment: "held") == nil)
        }
    }

    @Test("refunded, empty, unknown and missing payment statuses hide the card")
    func unknownPaymentHidesCard() {
        #expect(choose(payment: "refunded") == nil)
        #expect(choose(payment: "") == nil)
        #expect(choose(payment: "processing") == nil)
        #expect(choose(payment: nil) == nil)
        #expect(choose(payment: "refunded", expiresAt: expiry) == nil)
    }

    // MARK: Copy

    @Test("variant A copy matches the shipped card")
    func liveHoldCopy() {
        let variant = PaymentLifecycleVariant.liveHold
        #expect(variant.stepOneTitle == "A hold is placed on your card")
        #expect(variant.stepOneSubtitle == "No charge yet — funds are just reserved.")
        #expect(variant.stepThreeTitle == "Your card is charged after the session")
        #expect(variant.stepThreeSubtitle == "Usually within 15 minutes of the session ending.")
        #expect(variant.stepOneIcon == "lock.fill")
        #expect(variant.stepThreeIcon == "checkmark.seal.fill")
    }

    @Test("variant B copy matches UI-SPEC")
    func chargeScheduledCopy() {
        let variant = PaymentLifecycleVariant.chargeScheduled
        #expect(variant.stepOneTitle == "No hold is placed on your card")
        #expect(variant.stepOneSubtitle == "You haven't been charged yet.")
        #expect(variant.stepThreeTitle == "Your card is charged before the session")
        #expect(variant.stepThreeSubtitle == "About 24 hours before it starts, unless you cancel first.")
        #expect(variant.stepOneIcon == "creditcard")
        #expect(variant.stepThreeIcon == "creditcard")
    }

    @Test("variant C copy matches UI-SPEC")
    func alreadyChargedCopy() {
        let variant = PaymentLifecycleVariant.alreadyCharged
        #expect(variant.stepOneTitle == "Your card has been charged")
        #expect(variant.stepOneSubtitle == "Your payment was taken when you booked.")
        #expect(variant.stepThreeTitle == "Refunds follow our cancellation policy")
        #expect(variant.stepThreeSubtitle == "Cancel more than 24 hours before the start for a full refund.")
        #expect(variant.stepOneIcon == "checkmark.seal.fill")
        #expect(variant.stepThreeIcon == "creditcard")
    }
}

// MARK: - View model

/// The decoded booking, not a hard-coded step, decides what the card says.
@Suite("Request Sent payment variant", .serialized)
@MainActor
struct BookingRequestSentVariantTests {

    private typealias Fixtures = ClientBookingFixtures

    private var bookingUUID: UUID { UUID(uuidString: Fixtures.bookingId)! }

    /// Loads a view model against a stubbed `GET /client/bookings/:id`.
    ///
    /// - Parameters:
    ///   - status: The raw booking status. Passed explicitly on every row; the fixture default is `confirmed`.
    ///   - expiresAt: A raw JSON fragment for `authorization_expires_at`.
    private func loadedVariant(
        status: String,
        paymentStatus: String,
        isFree: Bool = false,
        expiresAt: String = "null"
    ) async -> (variant: PaymentLifecycleVariant?, state: LoadState) {
        let body = Fixtures.detailJSON(
            status: status,
            paymentStatus: paymentStatus,
            isFree: isFree,
            priceAmount: isFree ? nil : 4500,
            authorizationExpiresAt: expiresAt
        )
        let api = APITestFactory.make { request in
            Fixtures.response(for: request, body: body)
        }
        let vm = BookingRequestSentViewModel(bookingId: bookingUUID, api: api)
        await vm.load()
        return (vm.paymentVariant, vm.state)
    }

    @Test("a confirmed paid detail with a live hold loads the live-hold variant")
    func liveHold() async {
        let result = await loadedVariant(
            status: "confirmed", paymentStatus: "held", expiresAt: #""2099-01-02T00:00:00.000Z""#
        )
        #expect(result.state == .loaded)
        #expect(result.variant == .liveHold)
    }

    @Test("a confirmed paid detail with no PaymentIntent loads the charge-scheduled variant")
    func chargeScheduled() async {
        let result = await loadedVariant(status: "confirmed", paymentStatus: "none")
        #expect(result.state == .loaded)
        #expect(result.variant == .chargeScheduled)
    }

    @Test("a cancelled paid detail with payment_status none loads no card")
    func cancelledNoneHidesCard() async {
        let result = await loadedVariant(status: "cancelled", paymentStatus: "none")
        #expect(result.state == .loaded)
        #expect(result.variant == nil)
    }

    @Test("held with a null authorization_expires_at loads no card, never 'charged'")
    func heldWithoutExpiryHidesCard() async {
        let result = await loadedVariant(status: "confirmed", paymentStatus: "held")
        #expect(result.state == .loaded)
        #expect(result.variant == nil)
    }

    @Test("a completed paid detail with payment_status captured loads the already-charged variant")
    func captured() async {
        let result = await loadedVariant(status: "completed", paymentStatus: "captured")
        #expect(result.state == .loaded)
        #expect(result.variant == .alreadyCharged)
    }

    @Test("a free detail loads no card")
    func freeHidesCard() async {
        let result = await loadedVariant(status: "confirmed", paymentStatus: "none", isFree: true)
        #expect(result.state == .loaded)
        #expect(result.variant == nil)
    }

    @Test("a refunded paid detail loads no card")
    func refundedHidesCard() async {
        let result = await loadedVariant(status: "cancelled", paymentStatus: "refunded")
        #expect(result.state == .loaded)
        #expect(result.variant == nil)
    }
}
