//
//  ClickMeAPI+Payouts.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
    func getPayoutSummary() async throws -> SuccessDataResponse<PayoutSummaryData> {
        try await service.httpRequest(url: url(.getPayoutSummary), method: .get)
    }

    /// `POST /expert/payouts/withdraw` — initiate a withdrawal to the
    /// expert's connected bank account. Requires an `Idempotency-Key`
    /// header (auto-generated per call — retrying with a different key
    /// after a network drop could double-post; if the UI needs retry
    /// semantics, thread a stable key through from the caller instead).
    ///
    /// Rate-limited to 5 requests / 15 min per user. 409
    /// `WITHDRAW_IN_PROGRESS` when a concurrent withdrawal is in flight.
    func withdrawPayout(amount: Int) async throws -> SuccessDataResponse<WithdrawPayoutData> {
        try await service.httpRequest(
            url: url(.withdrawPayout),
            method: .post,
            parameters: ["amount": amount],
            headers: ["Idempotency-Key": UUID().uuidString]
        )
    }

    /// `POST /expert/connect/onboard` — create (or reuse) the expert's
    /// Stripe Connect Express account and return a fresh hosted Account
    /// Link URL. URL expires in ~5 minutes and is single-use — call this
    /// immediately before opening the browser; never cache.
    func startConnectOnboarding() async throws -> SuccessDataResponse<ConnectOnboardData> {
        try await service.httpRequest(url: url(.startConnectOnboarding), method: .post)
    }
}
