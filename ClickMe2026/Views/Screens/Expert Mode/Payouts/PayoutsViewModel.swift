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
                loadState = .failed(error.userMessage)
            }
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
