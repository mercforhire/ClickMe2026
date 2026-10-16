//
//  EarningsBreakdown.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Post-commission earnings snapshot for a booking, added alongside the
/// legacy `earnings` / `potential_earnings` / `consultation_fee` fields
/// on the three expert-facing endpoints
/// (`GET /expert/booking-requests`,
///  `GET /expert/booking-requests/:id`,
///  `GET /expert/bookings/:id/details`).
///
/// The legacy fields are **gross** — what the client pays — and are left
/// unchanged for wire compatibility. Any UI that labels a value as
/// "earnings" must switch to `netAmount` from this object. The spec
/// (`docs/ios/EXPERT-EARNINGS-BREAKDOWN.md`, §0) is explicit that
/// gross must never be shown under an "earnings" label as a fallback.
///
/// **Money units** — amounts arrive already divided into **major units**
/// (dollars for USD, yen for JPY etc). Zero-decimal currencies (JPY,
/// KRW, VND, CLP, ISK, XOF, XAF) are already scaled server-side, so the
/// client formatter must drive fraction-digit behavior off `currency`
/// rather than assuming 2 decimals. The fee is subtracted in minor units
/// on the server before conversion, so `gross - fee == net` holds
/// exactly with no float drift to correct for.
///
/// **Nullability** — `netAmount`, `platformFee`, `commissionPct`, and
/// `grossAmount` can each be `nil` in the `unavailable` branch (see
/// `FeeSource`). Branch on `feeSource`, not a null-check on
/// `netAmount` — a legitimate 0% expert returns `platformFee: 0`,
/// `commissionPct: 0`, `netAmount == grossAmount`, and
/// `feeSource: .booking`, which a `?? 0` coalesce would silently
/// misroute into the "unavailable" branch.
struct EarningsBreakdown: Decodable, Equatable {

    /// Where the commission came from — controls which UI branch to
    /// render. Unknown future values decode to `nil` so temporary drift
    /// doesn't blank out the whole earnings section; treat that as
    /// "degraded" and fall through to the `unavailable` treatment.
    enum FeeSource: String, Decodable {
        /// Exact commission was locked to this booking at charge time.
        /// State it plainly: "You earn $X".
        case booking
        /// Commission was derived from the expert's default rate because
        /// the booking hasn't been charged yet (long-lead, >24h out).
        /// Accurate unless the expert's default changes before charge.
        /// Qualify the label: "≈ $X" / "estimated".
        case expertDefault = "expert_default"
        /// No rate could be resolved (config gap, or an expert with no
        /// payout account). Only `grossAmount` is populated; fee, net,
        /// and pct are nil. Show session price + "Payout amount pending"
        /// — **do not** print gross as earnings.
        case unavailable
    }

    /// What the client pays. Same value as the legacy field. Major units.
    let grossAmount: Double?
    /// ClickMe's commission on this booking, major units.
    let platformFee: Double?
    /// What the expert receives — `grossAmount - platformFee`. This is
    /// the number to render as the headline.
    let netAmount: Double?
    /// Commission rate as a **percent**, not basis points — `15.0` means
    /// 15%. Legitimately `0` for zero-commission experts.
    let commissionPct: Double?
    /// ISO-4217 uppercase currency code. Always present.
    let currency: String
    /// Which branch we're in; drives the UI treatment. Always present.
    let feeSource: FeeSource?
}
