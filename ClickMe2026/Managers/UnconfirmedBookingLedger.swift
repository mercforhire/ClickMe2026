//
//  UnconfirmedBookingLedger.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Session-only record of paid confirms whose booking may exist on the server
/// without the app knowing (PAY-02, D-04).
///
/// A record is written when a paid `POST /bookings/confirm` starts. It is cleared
/// when the confirm ends with a 201, or with a server-coded error that proves no
/// booking was made. It stays when the outcome is unknown, when the client taps
/// "Not now", and when the client leaves the screen, so a later
/// `409 DUPLICATE_BOOKING` or `409 SLOT_UNAVAILABLE` for the same expert and slot
/// is read as "you may already have this booking" instead of "someone else took it".
///
/// The key is the expert and the slot start to the second, with no topic. D-04
/// says "same expert and slot", and `SLOT_UNAVAILABLE` also covers the caller's
/// own booking for a different topic at that slot, for which the hedged copy is
/// still true (`docs/ios/STRIPE-INTEGRATION.md` in the backend repo).
///
/// Held in memory by decision: it does not survive a relaunch. A relaunch reloads
/// My Bookings, and the server's `DUPLICATE_BOOKING` still reaches the alert
/// without a record, so persisting payment state would add a store with no new
/// safety. The record holds an expert id and a start time, never payment data.
@MainActor
final class UnconfirmedBookingLedger {

    static let shared = UnconfirmedBookingLedger()

    /// An expert and a slot start, rounded to the second.
    struct Key: Hashable {
        let expertId: UUID
        let startSecond: Int64

        init(expertId: UUID, start: Date) {
            self.expertId = expertId
            self.startSecond = Int64(start.timeIntervalSince1970.rounded())
        }
    }

    private var records: Set<Key> = []

    /// Internal so tests can make their own ledger and never write to `shared`.
    init() {}

    func record(expertId: UUID, start: Date) {
        records.insert(Key(expertId: expertId, start: start))
    }

    func clear(expertId: UUID, start: Date) {
        records.remove(Key(expertId: expertId, start: start))
    }

    func contains(expertId: UUID, start: Date) -> Bool {
        records.contains(Key(expertId: expertId, start: start))
    }

    func removeAll() {
        records.removeAll()
    }

    /// Whether the record survives a confirm answered with a server code.
    ///
    /// It survives exactly two codes:
    /// - `SLOT_UNAVAILABLE`: the slot may be the client's own booking (D-04).
    /// - `PAYMENT_IN_PROGRESS`: the confirm may still settle into a booking
    ///   (D-17). 04-08 classifies it as outcome unknown, so it does not normally
    ///   reach the server-coded arm, but the rule holds if it ever does.
    ///
    /// Every other code (and no code at all) means the confirm did not create a
    /// booking, so the record is cleared.
    static func keepsRecord(afterServerCode code: ErrorCode?) -> Bool {
        switch code {
        case .slotUnavailable, .paymentInProgress: true
        default: false
        }
    }
}
