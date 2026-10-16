//
//  PayoutsViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class PayoutsViewModel: ObservableObject {


    // MARK: State

    /// `GET /expert/payouts/summary` — live Stripe Connect balance +
    /// payout metadata. Nil while loading, on hard failure, or when
    /// Stripe Connect isn't onboarded yet (see `onboardingRequired`).
    @Published var summary: PayoutSummaryData?

    /// True when `getPayoutSummary` returned 400
    /// (`NO_PAYOUT_METHOD` / `KYC_INCOMPLETE`) — the view swaps the
    /// balance block for a "Complete payout setup" CTA.
    @Published var onboardingRequired: Bool

    /// `GET /expert/connect/status` snapshot. Nil when no connected
    /// account exists (404 → treat as `onboardingRequired`). When
    /// present, `chargesEnabled == false` OR `currentlyDue` non-empty
    /// means the expert can't accept bookings yet — the "Continue"
    /// CTA becomes "Finish verification" and calls `refresh-link`
    /// instead of `onboard`.
    @Published var connectStatus: ConnectStatusData?

    /// Count of upcoming bookings whose payment authorization is still
    /// held (Phase 27 lifecycle: money doesn't move until the session
    /// completes). When non-zero **and** the payout summary is 0/0,
    /// the view swaps the "You're ready to receive payouts" empty state
    /// for a "Payment on hold — you'll be paid after your session"
    /// card so the expert can distinguish "no earnings ever" from
    /// "earnings pending capture."
    ///
    /// Best-effort — a failure to fetch bookings leaves this at 0 so
    /// we default to the safer "ready" empty state rather than lying
    /// about pending money.
    @Published var upcomingHeldCount: Int

    /// First page of the caller's earnings ledger — used to render a
    /// compact "Recent activity" section under the balance area, with
    /// a "See all" affordance to push the full paginated screen when
    /// there are more rows. Empty when the fetch failed or the ledger
    /// is empty — the view collapses the section in both cases.
    @Published var recentTransactions: [EarningsTransactionItem]

    /// True when there are more rows beyond `recentTransactions`.
    /// Sourced from the pagination envelope's `hasMoreOrDerived` on
    /// the first-page fetch. Drives the visibility of the "See all"
    /// row.
    @Published var hasMoreTransactions: Bool

    @Published var loadState: LoadState

    // MARK: Stripe Connect onboarding
    @Published var connectOnboardingURL: URL?
    @Published var connectError: String?

    // MARK: Dependencies
    private let api: ClickMeAPI

    // MARK: Init

    init(api: ClickMeAPI = .shared) {
        self.summary = nil
        self.onboardingRequired = false
        self.connectStatus = nil
        self.upcomingHeldCount = 0
        self.recentTransactions = []
        self.hasMoreTransactions = false
        self.loadState = .idle
        self.connectOnboardingURL = nil
        self.connectError = nil
        self.api = api
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        summary: PayoutSummaryData? = PayoutSummaryData(
            availableAmount: 385000,
            pendingAmount: 42000,
            currency: "USD",
            nextPayoutDate: "2026-07-15",
            payoutMethod: "bank_transfer"
        ),
        onboardingRequired: Bool = false,
        upcomingHeldCount: Int = 0,
        recentTransactions: [EarningsTransactionItem] = [],
        hasMoreTransactions: Bool = false
    ) -> PayoutsViewModel {
        let vm = PayoutsViewModel()
        vm.summary = summary
        vm.onboardingRequired = onboardingRequired
        vm.upcomingHeldCount = upcomingHeldCount
        vm.recentTransactions = recentTransactions
        vm.hasMoreTransactions = hasMoreTransactions
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips when already loaded so preview seeds aren't
    /// clobbered.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading

        // Connect status is the authoritative signal for whether
        // onboarding is complete. Fetch it FIRST; the payout summary
        // can legitimately 400 for a Stripe-cleared account whose
        // balance object hasn't been initialized yet (fresh onboard,
        // no earnings), and treating that as "onboarding required"
        // was the bug: the screen kept showing "Complete payout
        // setup" long after Stripe returned `charges_enabled: true`.
        connectStatus = try? await api.getConnectStatus().data

        // Best-effort payout summary. A 400 (NO_PAYOUT_METHOD /
        // KYC_INCOMPLETE) is treated as a soft "no balance yet";
        // other errors are treated as hard failures.
        var summary400 = false
        do {
            let response = try await api.getPayoutSummary()
            summary = response.data
        } catch {
            summary = nil
            if case let NetworkError.httpError(status, _) = error, status == 400 {
                summary400 = true
            } else if connectStatus == nil {
                // Both requests failed hard — surface an error state so
                // the user can retry rather than sitting on a blank card.
                loadState = .failed(error.userMessage)
                return
            }
        }

        // Prefer connect status when we have it; only fall back to the
        // legacy "summary 400 → onboarding required" heuristic when
        // connect status was unavailable.
        if let status = connectStatus {
            onboardingRequired = !status.chargesEnabled || !status.currentlyDue.isEmpty
        } else {
            onboardingRequired = summary400
        }

        // Best-effort count of upcoming bookings whose money hasn't
        // captured yet — see `upcomingHeldCount`'s doc. Fetch failure
        // silently leaves the count at 0 so we don't invent a "on hold"
        // state for a user who doesn't have one.
        upcomingHeldCount = await fetchUpcomingHeldCount()

        // Best-effort first page of the earnings ledger — the "Recent
        // activity" section on the payouts screen. Failure leaves the
        // list empty and the section collapses; the balance/hold cards
        // above still render.
        await fetchRecentTransactions()

        loadState = .loaded
    }

    private func fetchRecentTransactions() async {
        do {
            let response = try await api.getEarningsTransactions(page: 1, limit: 20)
            recentTransactions = response.data.transactions
            hasMoreTransactions = response.data.pagination.hasMoreOrDerived
        } catch {
            recentTransactions = []
            hasMoreTransactions = false
        }
    }

    /// Filters the expert's upcoming bookings to those whose booking
    /// status implies the payment is still held (per Phase 27 —
    /// `pending_approval`, `confirmed`, `pending_reschedule`,
    /// `in_progress`). Free bookings are counted too — the copy on the
    /// "on hold" card is generic enough to remain honest for them.
    ///
    /// Not fatal on failure: returns 0 so the caller falls through to
    /// the "ready" empty state rather than promising money that isn't
    /// coming.
    private func fetchUpcomingHeldCount() async -> Int {
        do {
            let response = try await api.getExpertBookings(type: .upcoming, page: 1, limit: 100)
            return response.data.bookings.filter { booking in
                switch booking.status.code {
                case .pendingApproval, .confirmed, .pendingReschedule, .inProgress:
                    return true
                default:
                    return false
                }
            }.count
        } catch {
            return 0
        }
    }

    /// True when there's balance in Stripe **and** the expert has
    /// upcoming bookings whose payment authorization hasn't captured
    /// yet. Drives the "Payment on hold" empty state — distinguishes
    /// it from the fresh-onboard "You're ready to receive payouts"
    /// state. Only fires when the summary is 0/0 (or missing) since a
    /// user with real balance sees the balance hero regardless.
    var hasHeldPayments: Bool {
        upcomingHeldCount > 0
    }

    /// True when the expert has a Stripe Connect account with
    /// outstanding requirements (`currentlyDue` non-empty or
    /// `chargesEnabled == false`). Distinguishes "in-progress
    /// verification" from "no account yet" so we can pick between
    /// `refresh-link` (existing) and `onboard` (new).
    var hasIncompleteConnectAccount: Bool {
        guard let status = connectStatus else { return false }
        return !status.chargesEnabled || !status.currentlyDue.isEmpty
    }

    // MARK: - Stripe Connect onboarding

    /// Fetches a fresh single-use Account Link URL for the view to open
    /// in an in-app browser. URL expires in ~5 min so we never cache.
    ///
    /// Chooses `refresh-link` when a Connect account already exists
    /// with outstanding requirements, otherwise falls back to the
    /// initial `onboard` call. Both return the same shape.
    func startOnboarding() async {
        connectError = nil
        do {
            let response: SuccessDataResponse<ConnectOnboardData> = hasIncompleteConnectAccount
                ? try await api.refreshConnectLink()
                : try await api.startConnectOnboarding()
            connectOnboardingURL = URL(string: response.data.url)
        } catch {
            connectError = error.userMessage
        }
    }

    // MARK: - Formatting helpers

    static func currencyLabel(minorUnits: Int, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let value = Double(minorUnits) / 100.0
        formatter.maximumFractionDigits = Double(minorUnits).truncatingRemainder(dividingBy: 100) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value))
            ?? "\(currency) \(String(format: "%.0f", value))"
    }

    static func payoutDateLabel(_ isoDate: String) -> String {
        let inFormatter = DateFormatter()
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        inFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inFormatter.date(from: isoDate) else { return isoDate }

        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "MMMM d, yyyy"
        return outFormatter.string(from: date)
    }

    // MARK: - Error mapping

}
