//
//  UnconfirmedBookingLedgerTests.swift
//  ClickMe2026Tests
//
//  PAY-02 (D-04, D-17): the session-only record of confirms whose booking may
//  exist on the server. These rows pin the key and the keep rule; the view-model
//  lifecycle is covered in MakeABookingPaidFlowTests.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Unconfirmed booking ledger")
struct UnconfirmedBookingLedgerTests {

    private let expertId = UUID()
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A recorded expert and slot is contained until it is cleared")
    func recordThenClear() {
        let ledger = UnconfirmedBookingLedger()
        #expect(!ledger.contains(expertId: expertId, start: start))

        ledger.record(expertId: expertId, start: start)
        #expect(ledger.contains(expertId: expertId, start: start))

        ledger.clear(expertId: expertId, start: start)
        #expect(!ledger.contains(expertId: expertId, start: start))
    }

    @Test("A start 0.4 seconds later is the same slot")
    func sameSecondIsSameKey() {
        let ledger = UnconfirmedBookingLedger()
        ledger.record(expertId: expertId, start: start)

        #expect(ledger.contains(expertId: expertId, start: start.addingTimeInterval(0.4)))
        #expect(ledger.contains(expertId: expertId, start: start.addingTimeInterval(-0.4)))
    }

    @Test("Another second or another expert is a different key")
    func differentKeys() {
        let ledger = UnconfirmedBookingLedger()
        ledger.record(expertId: expertId, start: start)

        #expect(!ledger.contains(expertId: expertId, start: start.addingTimeInterval(1800)))
        #expect(!ledger.contains(expertId: UUID(), start: start))
    }

    @Test("removeAll empties the ledger")
    func removeAllEmpties() {
        let ledger = UnconfirmedBookingLedger()
        ledger.record(expertId: expertId, start: start)
        ledger.record(expertId: UUID(), start: start.addingTimeInterval(3600))

        ledger.removeAll()

        #expect(!ledger.contains(expertId: expertId, start: start))
    }

    @Test("Two ledgers do not share records")
    func ledgersAreIndependent() {
        let first = UnconfirmedBookingLedger()
        let second = UnconfirmedBookingLedger()
        first.record(expertId: expertId, start: start)

        #expect(!second.contains(expertId: expertId, start: start))
    }

    @Test("SLOT_UNAVAILABLE and PAYMENT_IN_PROGRESS keep the record")
    func keepsRecordForTwoCodes() {
        #expect(UnconfirmedBookingLedger.keepsRecord(afterServerCode: .slotUnavailable))
        #expect(UnconfirmedBookingLedger.keepsRecord(afterServerCode: .paymentInProgress))
    }

    @Test("Every other code, and no code, clears the record")
    func clearsForOtherCodes() {
        #expect(!UnconfirmedBookingLedger.keepsRecord(afterServerCode: .intentExpired))
        #expect(!UnconfirmedBookingLedger.keepsRecord(afterServerCode: .duplicateBooking))
        #expect(!UnconfirmedBookingLedger.keepsRecord(afterServerCode: .paymentFailed))
        #expect(!UnconfirmedBookingLedger.keepsRecord(afterServerCode: nil))
    }
}
