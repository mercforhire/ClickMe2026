//
//  CancelRefundPreviewTests.swift
//  ClickMe2026Tests
//
//  BOOK-08 (preview half): the client cancel confirm step states the refund the
//  backend will give. Mirrors `computeRefundAmountMinorUnits` in
//  `src/utils/refund.js` (strictly more than 24 hours is refundable, exactly
//  24 hours is not) and `paymentActionFields` in `src/utils/scaRecovery.js`.
//  Pure rule, no API.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Cancel refund preview")
struct CancelRefundPreviewTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let hour: TimeInterval = 3600

    private func facts(
        isFree: Bool = false,
        amount: Int? = 4500,
        currency: String? = "CAD",
        paymentStatus: String = "captured",
        authorizationExpiresAt: Date? = nil,
        paymentActionRequired: Bool = false,
        startsIn interval: TimeInterval = 72 * 3600
    ) -> CancelRefundPreview.Facts {
        CancelRefundPreview.Facts(
            isFree: isFree,
            priceAmountMinor: amount,
            currency: currency,
            paymentStatus: paymentStatus,
            authorizationExpiresAt: authorizationExpiresAt,
            paymentActionRequired: paymentActionRequired,
            start: now.addingTimeInterval(interval)
        )
    }

    // MARK: - Cases

    @Test("a free booking shows no money line")
    func free() {
        let result = CancelRefundPreview.refundCase(facts(isFree: true, amount: nil, currency: nil, paymentStatus: "none"), now: now)
        #expect(result == .free)
        #expect(CancelRefundPreview.text(for: result) == nil)
        #expect(CancelRefundPreview.iconName(for: result) == nil)
    }

    @Test("a live hold reads as a release")
    func liveHold() {
        let result = CancelRefundPreview.refundCase(
            facts(paymentStatus: "held", authorizationExpiresAt: now.addingTimeInterval(5 * 24 * hour)),
            now: now
        )
        #expect(result == .liveHold(amount: "CA$45.00"))
        #expect(CancelRefundPreview.text(for: result) == "The CA$45.00 hold on your card will be released, so you won't be charged.")
        #expect(CancelRefundPreview.iconName(for: result) == "lock.fill")
    }

    @Test("a live hold stays a release inside 24 hours")
    func liveHoldInsideWindow() {
        let result = CancelRefundPreview.refundCase(
            facts(paymentStatus: "held", authorizationExpiresAt: now.addingTimeInterval(3 * hour), startsIn: 2 * hour),
            now: now
        )
        #expect(result == .liveHold(amount: "CA$45.00"))
    }

    @Test("a charge more than 24 hours out is refundable")
    func chargedRefundable() {
        let result = CancelRefundPreview.refundCase(facts(startsIn: 24 * hour + 1), now: now)
        #expect(result == .chargedRefundable(amount: "CA$45.00"))
        #expect(CancelRefundPreview.text(for: result) == "Refund: CA$45.00, cancelled more than 24 hours before the start")
        #expect(CancelRefundPreview.iconName(for: result) == "creditcard")
    }

    @Test("exactly 24 hours out is not refundable")
    func exactBoundaryNotRefundable() {
        let result = CancelRefundPreview.refundCase(facts(startsIn: 24 * hour), now: now)
        #expect(result == .chargedNotRefundable(zero: "CA$0.00"))
        #expect(CancelRefundPreview.text(for: result) == "Refund: CA$0.00, the session starts within 24 hours")
        #expect(CancelRefundPreview.iconName(for: result) == "exclamationmark.triangle.fill")
    }

    @Test("held with no authorization expiry is a charge and follows the 24-hour rule")
    func heldWithoutExpiryIsCharged() {
        let near = CancelRefundPreview.refundCase(facts(paymentStatus: "held", startsIn: 2 * hour), now: now)
        #expect(near == .chargedNotRefundable(zero: "CA$0.00"))
        let far = CancelRefundPreview.refundCase(facts(paymentStatus: "held", startsIn: 72 * hour), now: now)
        #expect(far == .chargedRefundable(amount: "CA$45.00"))
    }

    @Test("payment_status none on a paid topic reads as not charged")
    func notChargedWhenNone() {
        let result = CancelRefundPreview.refundCase(facts(paymentStatus: "none"), now: now)
        #expect(result == .notChargedYet)
        #expect(CancelRefundPreview.text(for: result) == "You haven't been charged for this session, so nothing will be charged.")
    }

    @Test("payment_action_required reads as not charged, even when held")
    func notChargedWhenActionRequired() {
        let result = CancelRefundPreview.refundCase(
            facts(paymentStatus: "held", paymentActionRequired: true, startsIn: 2 * hour),
            now: now
        )
        #expect(result == .notChargedYet)
    }

    @Test("a paid booking missing its price or currency reads as the policy sentence")
    func amountUnknown() {
        let noPrice = CancelRefundPreview.refundCase(facts(amount: nil), now: now)
        #expect(noPrice == .amountUnknown)
        #expect(CancelRefundPreview.text(for: noPrice) == "Any refund follows our cancellation policy.")
        let noCurrency = CancelRefundPreview.refundCase(facts(currency: nil), now: now)
        #expect(noCurrency == .amountUnknown)
    }

    @Test("an unexpected payment_status falls to the policy sentence")
    func unexpectedStatus() {
        let result = CancelRefundPreview.refundCase(facts(paymentStatus: "refunded"), now: now)
        #expect(result == .amountUnknown)
    }

    @Test("a zero-decimal currency formats the zero through Money")
    func zeroDecimalCurrency() {
        let result = CancelRefundPreview.refundCase(
            facts(amount: 4500, currency: "JPY", startsIn: 2 * hour),
            now: now
        )
        #expect(result == .chargedNotRefundable(zero: Money.format(minorUnits: 0, currency: "JPY")))
        #expect(CancelRefundPreview.text(for: result)?.contains(Money.format(minorUnits: 0, currency: "JPY")) == true)
    }

    // MARK: - Footnote and emphasis

    @Test("the refund footnote shows only for the charged refundable case")
    func footnote() {
        #expect(CancelRefundPreview.showsRefundFootnote(.chargedRefundable(amount: "CA$45.00")))
        #expect(!CancelRefundPreview.showsRefundFootnote(.free))
        #expect(!CancelRefundPreview.showsRefundFootnote(.liveHold(amount: "CA$45.00")))
        #expect(!CancelRefundPreview.showsRefundFootnote(.chargedNotRefundable(zero: "CA$0.00")))
        #expect(!CancelRefundPreview.showsRefundFootnote(.notChargedYet))
        #expect(!CancelRefundPreview.showsRefundFootnote(.amountUnknown))
        #expect(!CancelRefundPreview.showsRefundFootnote(nil))
    }

    @Test("emphasis is the amount substring of the sentence")
    func emphasis() {
        let cases: [CancelRefundPreview.Case] = [
            .liveHold(amount: "CA$45.00"),
            .chargedRefundable(amount: "CA$45.00"),
            .chargedNotRefundable(zero: "CA$0.00"),
        ]
        for refundCase in cases {
            let amount = CancelRefundPreview.emphasis(for: refundCase)
            let sentence = CancelRefundPreview.text(for: refundCase)
            #expect(amount != nil)
            #expect(sentence?.contains(amount ?? "\u{0}") == true)
        }
        #expect(CancelRefundPreview.emphasis(for: .notChargedYet) == nil)
        #expect(CancelRefundPreview.emphasis(for: .amountUnknown) == nil)
        #expect(CancelRefundPreview.emphasis(for: .free) == nil)
    }

    // MARK: - Prohibition (BOOK-08)

    @Test("never previews a refund amount inside 24 hours, nor refund wording for a hold or an uncharged booking")
    func neverPromisesWhatTheBackendWillNotGive() {
        let inside = CancelRefundPreview.refundCase(facts(startsIn: 23 * hour), now: now)
        #expect(CancelRefundPreview.text(for: inside)?.contains("CA$45.00") == false)

        let hold = CancelRefundPreview.refundCase(
            facts(paymentStatus: "held", authorizationExpiresAt: now.addingTimeInterval(hour)),
            now: now
        )
        #expect(CancelRefundPreview.text(for: hold)?.contains("Refund") == false)

        let uncharged = CancelRefundPreview.refundCase(facts(paymentStatus: "none"), now: now)
        #expect(CancelRefundPreview.text(for: uncharged)?.contains("Refund") == false)
        #expect(CancelRefundPreview.text(for: uncharged)?.contains("refunded") == false)
    }

    // MARK: - Decoding (D-14)

    private func detailJSON(extra: String) -> Data {
        Data(#"""
        {
          "booking_id":"11111111-1111-4111-8111-111111111111",
          "status":"confirmed",
          "start_time":"2099-01-01T10:00:00Z",
          "end_time":"2099-01-01T11:00:00Z",
          "meeting_type":"in_app_voice",
          "expert_timezone":"UTC",
          "payment_status":"held",
          "topic":{"id":"33333333-3333-4333-8333-333333333333","title":"Career","duration_mins":30,"is_free":false,"price":{"amount":4500,"currency":"CAD"}},
          "expert":{"id":"22222222-2222-4222-8222-222222222222","full_name":"Ada Lovelace","avatar_url":null,"title":null},
          "join_link":null,
          "client_notes":null,
          "private_note":null,
          "reschedule":null,
          "authorization_expires_at":null,
          "can_join":null\#(extra)
        }
        """#.utf8)
    }

    private func decode(_ data: Data) throws -> ClientBookingDetail {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ClientBookingDetail.self, from: data)
    }

    @Test("ClientBookingDetail decodes payment_action_required when present and nil when absent")
    func decodesPaymentActionRequired() throws {
        let present = try decode(detailJSON(extra: #", "payment_action_required": true"#))
        #expect(present.paymentActionRequired == true)
        #expect(CancelRefundPreview.Facts(detail: present).paymentActionRequired)

        let absent = try decode(detailJSON(extra: ""))
        #expect(absent.paymentActionRequired == nil)
        #expect(!CancelRefundPreview.Facts(detail: absent).paymentActionRequired)
    }
}
