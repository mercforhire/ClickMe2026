//
//  PayoutSummaryData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `GET /expert/payouts/summary`.
///
/// Live Stripe Connect balance — fetched from Stripe on every request,
/// never cached. Server returns 400 `NO_PAYOUT_METHOD` when the expert
/// has no Stripe Connect account yet, and 400 `KYC_INCOMPLETE` when
/// verification hasn't been completed. Amounts are integer minor units.
struct PayoutSummaryData: Decodable {
    /// Live Stripe available balance in minor units — what the "Withdraw"
    /// button can transfer today.
    let availableAmount: Int
    /// Live Stripe pending balance in minor units — captured but in the
    /// hold/dispute window; not withdrawable yet.
    let pendingAmount: Int
    /// ISO 3-letter uppercase — connected account's payout currency.
    let currency: String
    /// `YYYY-MM-DD` from the payout schedule; `nil` for manual-schedule
    /// accounts.
    let nextPayoutDate: String?
    /// Always `"bank_transfer"` in v1.
    let payoutMethod: String
    /// True when `availableAmount >= minWithdrawableAmount`. When false,
    /// the Withdraw button should be disabled.
    let canWithdraw: Bool
    /// Minimum withdrawal in minor units (configured server-side via
    /// `MIN_WITHDRAWABLE_{CURRENCY}` env).
    let minWithdrawableAmount: Int
}
