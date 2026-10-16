//
//  PayoutsView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Full payout detail screen — pushed from the Expert Dashboard's
/// Financial Summary card. Shows the live Stripe Connect balance and
/// next payout date. Payouts happen automatically on Stripe's schedule;
/// there is no manual withdrawal. When Stripe Connect isn't onboarded
/// yet, the balance block is swapped for an onboarding CTA that opens
/// Stripe's hosted Account Link URL in Safari.
struct PayoutsView: View {

    @StateObject private var viewModel: PayoutsViewModel
    /// Owns the ASWebAuthenticationSession for the Stripe Connect
    /// onboarding flow. Held on the view (not the view model) so the
    /// UI-facing presentation lifecycle isn't tied to view-model state.
    @State private var onboardingSession = ConnectOnboardingSession()

    // MARK: Design tokens — Luminous Dark

    private let bg = Brand.surface
    private let cardBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    private let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let pendingBg = Color(red: 0.078, green: 0.145, blue: 0.100)
    private let pendingBdr = Color(red: 0.155, green: 0.290, blue: 0.200)
    private let brandGreen = Brand.primary
    private let onSurface = Brand.onSurface
    private let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.610)
    private let onPrimary = Brand.onPrimary

    // MARK: Init

    init(viewModel: PayoutsViewModel = PayoutsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Payouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        // Present the Stripe hosted onboarding URL in an in-app
        // ASWebAuthenticationSession. When Safari navigates to
        // clickme://connect/return (via the backend's 302), the
        // session closes and we refresh status. If the callback URL
        // is the refresh variant, mint a new link and reopen.
        .onChange(of: viewModel.connectOnboardingURL) { _, url in
            guard let url else { return }
            viewModel.connectOnboardingURL = nil
            onboardingSession.start(url: url) { outcome in
                switch outcome {
                case .completed(let callback):
                    Task {
                        if callback.isConnectRefresh {
                            await viewModel.startOnboarding()
                        } else {
                            await viewModel.reload()
                        }
                    }
                case .cancelled:
                    // User dismissed the sheet — nothing to do. The
                    // onboarding CTA stays visible until they retry.
                    break
                }
            }
        }
        .alert(
            "Couldn't open payout setup",
            isPresented: Binding(
                get: { viewModel.connectError != nil },
                set: { if !$0 { viewModel.connectError = nil } }
            ),
            presenting: viewModel.connectError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.onboardingRequired {
                    onboardCard
                } else if isReadyWithNoEarnings {
                    // Two empty-state variants: "money is on its way"
                    // (upcoming sessions carrying held authorizations,
                    // Phase 27) vs the fresh-onboard "no sessions yet"
                    // case. `hasHeldPayments` disambiguates so a UAT
                    // expert with a paid but not-yet-captured booking
                    // sees the right message instead of the
                    // anticlimactic "no earnings" copy.
                    if viewModel.hasHeldPayments {
                        holdPendingCard
                    } else {
                        readyEmptyCard
                    }
                    payoutMetaCard
                } else {
                    balanceHero
                    payoutMetaCard
                    payoutScheduleNote
                }

                if !viewModel.recentTransactions.isEmpty {
                    recentActivitySection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Recent activity section

    /// Compact "Recent activity" card — first page of the earnings
    /// ledger, capped at 5 rows for the payouts screen. When there are
    /// more (either `hasMoreTransactions` or the first page already
    /// exceeds the cap), a "See all" chevron pushes the full paginated
    /// `TransactionsView`. Only mounted when the fetch returned at
    /// least one row — an empty ledger keeps the section collapsed
    /// entirely so a clean-slate expert doesn't see a "no activity"
    /// dead space competing with the ready/hold hero above.
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent activity")
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(onSurface)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(previewRows.enumerated()), id: \.element.id) { index, item in
                    EarningsTransactionRow(item: item)
                    if index < previewRows.count - 1 {
                        Rectangle()
                            .fill(cardBorder)
                            .frame(height: 1)
                            .padding(.horizontal, 14)
                    }
                }

                if shouldShowSeeAll {
                    Rectangle()
                        .fill(cardBorder)
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                    NavigationLink {
                        TransactionsView()
                    } label: {
                        HStack {
                            Text("See all activity")
                                .font(.brand(.subheadline, weight: .semibold))
                                .foregroundColor(brandGreen)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(brandGreen)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1))
            )
        }
    }

    /// First N rows to show inline. Capping at 5 avoids the section
    /// dominating the screen when the ledger is large.
    private var previewRows: [EarningsTransactionItem] {
        Array(viewModel.recentTransactions.prefix(5))
    }

    /// Show the "See all" affordance when either the server flagged
    /// more pages OR the first page itself already exceeded the
    /// inline cap.
    private var shouldShowSeeAll: Bool {
        viewModel.hasMoreTransactions || viewModel.recentTransactions.count > previewRows.count
    }

    /// True once Stripe has cleared the account but the expert hasn't
    /// earned anything yet. Distinguishes the "onboarding just
    /// completed" moment from steady-state — a bare `$0.00` balance
    /// card is anticlimactic after finishing the flow.
    ///
    /// Also fires when the payout summary is nil (Stripe hasn't
    /// initialized the balance object yet) as long as onboarding
    /// isn't required — otherwise the balance hero would render `—`.
    private var isReadyWithNoEarnings: Bool {
        guard !viewModel.onboardingRequired else { return false }
        guard let s = viewModel.summary else { return true }
        return s.availableAmount == 0 && s.pendingAmount == 0
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(onSurface)
            Text("Loading payouts…")
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(onSurfaceVar)
            Text("Couldn't load payouts")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Balance hero

    private var balanceHero: some View {
        VStack(spacing: 8) {
            Text("AVAILABLE BALANCE")
                .font(.brand(.caption2, weight: .semibold))
                .foregroundColor(onSurfaceVar)
                .tracking(1.4)

            Text(availableLabel)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(brandGreen)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            if let s = viewModel.summary, s.pendingAmount > 0 {
                Text("\(pendingLabel) pending")
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(onSurfaceVar)
            }

            eligibilityAffordance
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    /// Renders one of two states beneath the balance:
    /// - Positive `availableAmount` on a fully-verified Connect
    ///   account → "Eligible for next payout" pill.
    /// - Otherwise → nothing (KYC pending, empty balance, or negative
    ///   residual balance — all covered by other UI).
    ///
    /// The old gate on `canWithdraw` was dropped because the backend
    /// removed both `can_withdraw` and `min_withdrawable_amount` from
    /// the summary payload (Stripe-integration doc §5, quick
    /// 260820‑lh4) — payouts are fully automatic now and there's no
    /// threshold in any form. Gating on a positive balance +
    /// verified Connect status preserves the "you're all set for the
    /// next auto payout" affirmation without inventing a threshold
    /// or lying about a negative dispute-residue balance.
    @ViewBuilder
    private var eligibilityAffordance: some View {
        if let s = viewModel.summary,
           s.availableAmount > 0,
           !viewModel.hasIncompleteConnectAccount
        {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                Text("Eligible for next payout")
                    .font(.brand(.caption, weight: .semibold))
            }
            .foregroundColor(brandGreen)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(brandGreen.opacity(0.14)))
            .padding(.top, 4)
        }
    }

    // MARK: - Payout meta card

    private var payoutMetaCard: some View {
        VStack(spacing: 0) {
            metaRow(label: "Next payout", value: nextPayoutValue)
            divider
            metaRow(label: "Payout method", value: payoutMethodValue)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1))
        )
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(onSurfaceVar)
            Spacer()
            Text(value)
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(onSurface)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle()
            .fill(cardBorder)
            .frame(height: 1)
            .padding(.horizontal, 14)
    }

    // MARK: - Payout schedule note

    private var payoutScheduleNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.subheadline.weight(.regular))
                .foregroundColor(onSurfaceVar)
            Text("Your available balance is transferred to your bank automatically on the schedule above.")
                .font(.brand(.caption, weight: .regular))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardBg)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1))
        )
    }

    // MARK: - Ready-but-empty state (payouts set up, no earnings yet)

    /// Shown once the expert has completed Stripe Connect onboarding
    /// but hasn't earned anything yet. Replaces the anticlimactic
    /// `$0.00` balance hero with a success confirmation, so the
    /// screen feels like a positive milestone instead of an empty
    /// dashboard.
    private var readyEmptyCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(brandGreen.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.title.weight(.bold))
                    .foregroundColor(brandGreen)
            }

            VStack(spacing: 6) {
                Text("You're ready to receive payouts")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(onSurface)
                    .multilineTextAlignment(.center)
                Text("Once you complete a paid session, your earnings will appear here and pay out on the schedule below.")
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(pendingBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(pendingBdr, lineWidth: 1))
        )
    }

    // MARK: - Payment on hold state (upcoming sessions carrying auths)

    /// Shown when the expert has 0/0 balance but at least one upcoming
    /// booking whose payment is authorized-but-not-captured (Phase 27).
    /// Reassures the user that money is coming — distinguishes their
    /// state from a truly fresh-onboard "no sessions ever booked"
    /// expert who would see `readyEmptyCard` instead.
    ///
    /// Uses an hourglass rather than a checkmark so the affordance
    /// reads as "in-flight" rather than "complete". Warm amber tint
    /// matches the "hold placed" pill on the client-side booking
    /// detail (Phase 27 pattern) so a client and expert looking at the
    /// same booking see visually consistent state.
    private var holdPendingCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: "hourglass")
                    .font(.title.weight(.bold))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 6) {
                Text("Payment on hold")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(onSurface)
                    .multilineTextAlignment(.center)
                Text(holdPendingSubtitle)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.orange.opacity(0.45), lineWidth: 1))
        )
    }

    /// Pluralised subtitle. Count comes from the VM, which counts
    /// upcoming bookings with a `held`-style status regardless of
    /// whether the topic was free — the copy stays honest either way
    /// (free sessions just contribute 0 to the eventual balance).
    private var holdPendingSubtitle: String {
        let n = viewModel.upcomingHeldCount
        let sessions = n == 1 ? "1 upcoming session" : "\(n) upcoming sessions"
        return "\(sessions). You'll be paid once your session\(n == 1 ? "" : "s") complete\(n == 1 ? "s" : "")."
    }

    // MARK: - Onboarding CTA

    private var onboardCard: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(brandGreen.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: "creditcard")
                    .font(.title.weight(.regular))
                    .foregroundColor(brandGreen)
            }

            VStack(spacing: 6) {
                Text("Complete payout setup")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(brandGreen)
                Text("Verify your identity and connect a bank account to start receiving your earnings.")
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                // Stripe Connect onboarding opens an external URL /
                // browser — messy to hand off mid-call. Gate it.
                guard CallCenter.shared.attempt("set up payouts") else { return }
                Task { await viewModel.startOnboarding() }
            } label: {
                Text("Continue")
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(brandGreen)
                            .shadow(color: brandGreen.opacity(0.45), radius: 14, x: 0, y: 4)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(pendingBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(pendingBdr, lineWidth: 1))
        )
    }

    // MARK: - Derived labels

    private var availableLabel: String {
        guard let s = viewModel.summary else { return "—" }
        return PayoutsViewModel.currencyLabel(minorUnits: s.availableAmount, currency: s.currency)
    }

    private var pendingLabel: String {
        guard let s = viewModel.summary else { return "—" }
        return PayoutsViewModel.currencyLabel(minorUnits: s.pendingAmount, currency: s.currency)
    }

    private var nextPayoutValue: String {
        guard let s = viewModel.summary else { return "—" }
        if let iso = s.nextPayoutDate {
            return PayoutsViewModel.payoutDateLabel(iso)
        }
        return "Manual schedule"
    }

    private var payoutMethodValue: String {
        // Server currently only supports `bank_transfer` in v1. Match its
        // enum verbatim so any future values still render (just less prettily).
        switch viewModel.summary?.payoutMethod {
        case "bank_transfer": return "Bank Transfer"
        case let other?:      return other.replacingOccurrences(of: "_", with: " ").capitalized
        case nil:             return "—"
        }
    }

}

// MARK: - Previews

#Preview("Payouts") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Payouts") {
        PayoutsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Zero Balance") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Payouts") {
        PayoutsView(viewModel: .previewSeed(
            summary: PayoutSummaryData(
                availableAmount: 0,
                pendingAmount: 8000,
                currency: "USD",
                nextPayoutDate: "2026-07-15",
                payoutMethod: "bank_transfer"
            )
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Onboarding Required") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Payouts") {
        PayoutsView(viewModel: .previewSeed(summary: nil, onboardingRequired: true))
    }
    .preferredColorScheme(.dark)
}

#Preview("Payment on hold — 1 session") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Payouts") {
        PayoutsView(viewModel: .previewSeed(
            summary: PayoutSummaryData(
                availableAmount: 0,
                pendingAmount: 0,
                currency: "CAD",
                nextPayoutDate: nil,
                payoutMethod: "bank_transfer"
            ),
            upcomingHeldCount: 1
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Payment on hold — multiple") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Payouts") {
        PayoutsView(viewModel: .previewSeed(
            summary: PayoutSummaryData(
                availableAmount: 0,
                pendingAmount: 0,
                currency: "CAD",
                nextPayoutDate: nil,
                payoutMethod: "bank_transfer"
            ),
            upcomingHeldCount: 3
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Payouts") {
        PayoutsView()
    }
    .preferredColorScheme(.dark)
}
