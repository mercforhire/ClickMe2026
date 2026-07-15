//
//  PayoutsViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class PayoutsViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: State

    /// `GET /expert/payouts/summary` — live Stripe Connect balance +
    /// payout metadata. Nil while loading, on hard failure, or when
    /// Stripe Connect isn't onboarded yet (see `onboardingRequired`).
    @Published var summary: PayoutSummaryData?

    /// True when `getPayoutSummary` returned 400
    /// (`NO_PAYOUT_METHOD` / `KYC_INCOMPLETE`) — the view swaps the
    /// balance block for a "Complete payout setup" CTA.
    @Published var onboardingRequired: Bool

    @Published var loadState: LoadState

    // MARK: Withdrawal
    @Published var isWithdrawing: Bool
    @Published var withdrawError: String?
    @Published var withdrawSuccessMessage: String?
    /// True when the "confirm withdrawal?" alert is showing.
    @Published var showWithdrawConfirm: Bool

    // MARK: Stripe Connect onboarding
    @Published var connectOnboardingURL: URL?
    @Published var connectError: String?

    // MARK: Dependencies
    private let api: ClickMeAPI

    // MARK: Init

    init(api: ClickMeAPI = .shared) {
        self.summary = nil
        self.onboardingRequired = false
        self.loadState = .idle
        self.isWithdrawing = false
        self.withdrawError = nil
        self.withdrawSuccessMessage = nil
        self.showWithdrawConfirm = false
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
            payoutMethod: "bank_transfer",
            canWithdraw: true,
            minWithdrawableAmount: 5000
        ),
        onboardingRequired: Bool = false
    ) -> PayoutsViewModel {
        let vm = PayoutsViewModel()
        vm.summary = summary
        vm.onboardingRequired = onboardingRequired
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
        do {
            let response = try await api.getPayoutSummary()
            summary = response.data
            onboardingRequired = false
            loadState = .loaded
        } catch {
            if case let NetworkError.httpError(status, _) = error, status == 400 {
                // Onboarding gate — not a hard failure. Present the CTA
                // instead of the balance block.
                summary = nil
                onboardingRequired = true
                loadState = .loaded
            } else {
                summary = nil
                onboardingRequired = false
                loadState = .failed(Self.errorMessage(for: error))
            }
        }
    }

    // MARK: - Withdraw

    func confirmWithdrawal() {
        guard let summary, summary.canWithdraw, !isWithdrawing else { return }
        showWithdrawConfirm = true
    }

    /// Actually POSTs the withdrawal. Called by the confirm-alert's
    /// destructive button. Refreshes the summary on success so the UI
    /// reflects the new balance immediately.
    func performWithdrawal() async {
        guard !isWithdrawing else { return }
        guard let summary, summary.canWithdraw else { return }

        withdrawError = nil
        withdrawSuccessMessage = nil
        isWithdrawing = true
        defer { isWithdrawing = false }

        do {
            let response = try await api.withdrawPayout(amount: summary.availableAmount)
            withdrawSuccessMessage = "Withdrawal of \(Self.currencyLabel(minorUnits: response.data.amount, currency: response.data.currency)) is processing."
            await reload()
        } catch {
            withdrawError = Self.errorMessage(for: error)
        }
    }

    // MARK: - Stripe Connect onboarding

    /// Fetches a fresh single-use Account Link URL for the view to open
    /// in an in-app browser. URL expires in ~5 min so we never cache.
    func startOnboarding() async {
        connectError = nil
        do {
            let response = try await api.startConnectOnboarding()
            connectOnboardingURL = URL(string: response.data.url)
        } catch {
            connectError = Self.errorMessage(for: error)
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

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
