//
//  EarningsTransactionItem.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Single row from `GET /expert/earnings/transactions`.
///
/// **Units — minor units** (`7500` means $75.00). Divide by 100 (or by
/// the currency's minor-unit exponent, for zero-decimal currencies like
/// JPY / KRW). Different convention from `EarningsBreakdown`, which
/// emits already-divided major units — see the transactions spec §3.
///
/// **Nullability discipline** — every optional field can legitimately
/// be `nil` when the underlying booking / topic / client can't be
/// resolved (deleted or orphaned reference). The backend never drops
/// the row and never 500s on a missing join. Callers must render the
/// row anyway and show a neutral placeholder (`—`) for any nil field.
struct EarningsTransactionItem: Decodable, Identifiable, Equatable {

    /// Ledger's own `expert_earnings.payout_status`. Distinct from
    /// Stripe's payout schedule — see the spec §4.
    ///
    /// `settledDirect` (`"settled_direct"`) is the **normal terminal
    /// state for current sessions** — the money is created on the
    /// expert's connected Stripe account via direct-charge and Stripe
    /// pays out on its own schedule (backend never transfers). It
    /// never advances to `paid`. Do not bucket it with `pending`, and
    /// do not label it as "in your bank" — Stripe holds funds on a
    /// rolling schedule before release. Ships as of task `260816-wyh`;
    /// the DB migration is already backfilling this value in
    /// production so we must decode it before the next release even
    /// though new-row writes haven't shipped yet.
    ///
    /// `paid` is legacy — it meant "platform transferred this earning
    /// to the connected-account balance" back when the platform did
    /// transfers. It never fires on new rows now; only pre-migration
    /// rows still carry it.
    enum PayoutStatus: String, Decodable {
        case pending
        case processing
        case paid
        case settledDirect = "settled_direct"
        case failed
    }

    /// `expert_earnings` row id — used as `Identifiable.id` for
    /// SwiftUI diffing.
    let id: UUID
    /// Linked booking's id when the source session can still be
    /// resolved. `nil` for ledger rows without a live booking.
    let bookingId: UUID?
    /// The session's start time — sourced from `bookings.start_time`,
    /// **not** the ledger's `createdAt`. Use this in the row's date
    /// label. `nil` when the booking is unresolvable.
    let sessionDate: Date?
    /// Topic title on the booked session, or `nil` when unresolvable.
    let topicTitle: String?
    /// `"First Last"` or just `"First"`, or `nil` when the client
    /// profile can't be resolved.
    let clientName: String?
    /// What the client paid, in minor units.
    let grossAmount: Int
    /// Platform commission on this row, in minor units.
    let commissionAmount: Int
    /// What the expert receives — `grossAmount - commissionAmount`,
    /// in minor units. Headline this in per-row displays.
    let netAmount: Int
    /// ISO-4217 uppercase.
    let currency: String
    /// Ledger state — see `PayoutStatus`.
    let payoutStatus: PayoutStatus?
    /// When the admin transfer flow marked the row processed. `nil`
    /// while `payoutStatus` is `.pending` / `.processing`.
    let processedAt: Date?
    /// When the ledger row was created. Not the session date — that's
    /// `sessionDate` — but useful as a fallback timestamp if
    /// `sessionDate` is nil.
    let createdAt: Date
}
