//
//  ClickMeAPI+Payouts.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    /// `GET /expert/earnings/weekly` — weekly gross/net earnings for the
    /// authenticated expert. Week boundaries anchored to Monday in the
    /// expert's timezone. Pass `weekStart` (a Monday `YYYY-MM-DD`) to
    /// query a past week; omit for the current week.
    func getWeeklyEarnings(weekStart: String? = nil) async throws -> SuccessDataResponse<WeeklyEarningsData> {
        var params: [String: Any] = [:]
        if let weekStart { params["week_start"] = weekStart }
        return try await service.httpRequest(
            url: url(.getWeeklyEarnings),
            method: .get,
            parameters: params.isEmpty ? nil : params
        )
    }

    /// `GET /expert/payouts/summary` — live Stripe Connect balance +
    /// payout metadata. Returns 400 `NO_PAYOUT_METHOD` or `KYC_INCOMPLETE`
    /// when the expert isn't fully onboarded yet — surface those to the
    /// user with the Connect onboarding link.
    ///
    /// **`KYC_INCOMPLETE` is no longer terminal** — the read path
    /// self-heals a stale KYC row against live Stripe truth on the
    /// reject branch, so a pull-to-refresh after re-completing Stripe
    /// onboarding may now succeed without any other change. Don't
    /// cache 400 as permanent client-side.
    func getPayoutSummary() async throws -> SuccessDataResponse<PayoutSummaryData> {
        try await service.httpRequest(url: url(.getPayoutSummary), method: .get)
    }

    /// `GET /expert/earnings/transactions` — paginated ledger of the
    /// caller's per-session earnings, newest-first. Server clamps
    /// `limit` to `[1, 100]`; caller can request up to 100 per page.
    /// Server enforces expert-role scoping and ignores any client-
    /// supplied `expert_id`.
    ///
    /// Amounts on rows are **minor units** — different from
    /// `earnings_breakdown` (major units). See §3 of the transactions
    /// spec.
    func getEarningsTransactions(
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SuccessDataResponse<EarningsTransactionsData> {
        try await service.httpRequest(
            url: url(.getEarningsTransactions),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    /// `POST /expert/connect/onboard` — create (or reuse) the expert's
    /// Stripe Connect Express account and return a fresh hosted Account
    /// Link URL. URL expires in ~5 minutes and is single-use — call this
    /// immediately before opening the browser; never cache.
    func startConnectOnboarding() async throws -> SuccessDataResponse<ConnectOnboardData> {
        try await service.httpRequest(url: url(.startConnectOnboarding), method: .post)
    }

    /// `GET /expert/connect/status` — live Stripe readiness for the
    /// authenticated expert. `charges_enabled` gates the ability to
    /// accept bookings; `currently_due` lists Stripe requirements the
    /// account still needs to satisfy. Returns 404 when no connected
    /// account exists yet.
    func getConnectStatus() async throws -> SuccessDataResponse<ConnectStatusData> {
        try await service.httpRequest(url: url(.getConnectStatus), method: .get)
    }

    /// `POST /expert/connect/refresh-link` — mints a fresh hosted
    /// onboarding link when a previous one expired. Same short-lived,
    /// single-use semantics as `startConnectOnboarding`.
    func refreshConnectLink() async throws -> SuccessDataResponse<ConnectOnboardData> {
        try await service.httpRequest(url: url(.refreshConnectLink), method: .post)
    }
}
