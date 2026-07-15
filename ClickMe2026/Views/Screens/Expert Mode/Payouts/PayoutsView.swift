//
//  PayoutsView.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Full payout detail screen — pushed from the Expert Dashboard's
/// Financial Summary card. Shows the live Stripe Connect balance, next
/// payout date, min withdrawable amount, and a Withdraw button (with a
/// confirmation prompt). When Stripe Connect isn't onboarded yet, the
/// balance block is swapped for an onboarding CTA that opens Stripe's
/// hosted Account Link URL in Safari.
struct PayoutsView: View {

    @StateObject private var viewModel: PayoutsViewModel
    @Environment(\.openURL) private var openURL

    // MARK: Design tokens — Luminous Dark

    private let bg = Color(red: 0.075, green: 0.075, blue: 0.075)
    private let cardBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    private let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let pendingBg = Color(red: 0.078, green: 0.145, blue: 0.100)
    private let pendingBdr = Color(red: 0.155, green: 0.290, blue: 0.200)
    private let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    private let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    private let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.610)
    private let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)

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
        .onChange(of: viewModel.connectOnboardingURL) { url in
            guard let url else { return }
            openURL(url)
            viewModel.connectOnboardingURL = nil
        }
        .confirmationDialog(
            withdrawConfirmMessage,
            isPresented: $viewModel.showWithdrawConfirm,
            titleVisibility: .visible
        ) {
            Button("Withdraw", role: .destructive) {
                Task { await viewModel.performWithdrawal() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Withdrawal failed",
            isPresented: Binding(
                get: { viewModel.withdrawError != nil },
                set: { if !$0 { viewModel.withdrawError = nil } }
            ),
            presenting: viewModel.withdrawError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert(
            "Withdrawal submitted",
            isPresented: Binding(
                get: { viewModel.withdrawSuccessMessage != nil },
                set: { if !$0 { viewModel.withdrawSuccessMessage = nil } }
            ),
            presenting: viewModel.withdrawSuccessMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
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
                } else {
                    balanceHero
                    payoutMetaCard
                    withdrawSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(onSurface)
            Text("Loading payouts…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(onSurfaceVar)
            Text("Couldn't load payouts")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
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
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .tracking(1.4)

            Text(availableLabel)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(brandGreen)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            if let s = viewModel.summary, s.pendingAmount > 0 {
                Text("\(pendingLabel) pending")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(onSurfaceVar)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Payout meta card

    private var payoutMetaCard: some View {
        VStack(spacing: 0) {
            metaRow(label: "Next payout", value: nextPayoutValue)
            divider
            metaRow(label: "Payout method", value: payoutMethodValue)
            divider
            metaRow(label: "Minimum withdrawal", value: minWithdrawableValue)
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
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(onSurfaceVar)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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

    // MARK: - Withdraw section

    private var withdrawSection: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.confirmWithdrawal()
            } label: {
                Group {
                    if viewModel.isWithdrawing {
                        ProgressView().tint(onPrimary)
                    } else {
                        Text("Withdraw \(availableLabel)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(onPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(brandGreen.opacity(canWithdraw ? 1.0 : 0.35))
                        .shadow(
                            color: brandGreen.opacity(canWithdraw ? 0.45 : 0),
                            radius: 14, x: 0, y: 4
                        )
                )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(!canWithdraw || viewModel.isWithdrawing)

            if !canWithdraw, let s = viewModel.summary {
                Text("Available balance must be at least \(PayoutsViewModel.currencyLabel(minorUnits: s.minWithdrawableAmount, currency: s.currency)) to withdraw.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Onboarding CTA

    private var onboardCard: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(brandGreen.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: "creditcard")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(brandGreen)
            }

            VStack(spacing: 6) {
                Text("Complete payout setup")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(brandGreen)
                Text("Verify your identity and connect a bank account to start receiving your earnings.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task { await viewModel.startOnboarding() }
            } label: {
                Text("Continue")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
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

    private var minWithdrawableValue: String {
        guard let s = viewModel.summary else { return "—" }
        return PayoutsViewModel.currencyLabel(minorUnits: s.minWithdrawableAmount, currency: s.currency)
    }

    private var canWithdraw: Bool {
        viewModel.summary?.canWithdraw ?? false
    }

    /// Copy shown as the confirmation-dialog title. Includes the actual
    /// amount so the user can double-check before firing.
    private var withdrawConfirmMessage: String {
        "Withdraw \(availableLabel) to your bank account?"
    }
}

// MARK: - Preview harness

private enum PayoutsPreviewRoute: Hashable { case payouts }

private struct PayoutsPreviewHarness: View {
    let viewModel: PayoutsViewModel
    @State private var path: [PayoutsPreviewRoute]

    init(viewModel: PayoutsViewModel) {
        self.viewModel = viewModel
        _path = State(initialValue: [.payouts])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Dashboard")
                NavigationLink("Payouts", value: PayoutsPreviewRoute.payouts)
            }
            .navigationTitle("Expert")
            .navigationDestination(for: PayoutsPreviewRoute.self) { _ in
                PayoutsView(viewModel: viewModel)
            }
        }
    }
}

private struct LiveFetchPayoutsPreviewHarness: View {
    @State private var path: [PayoutsPreviewRoute] = [.payouts]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Dashboard")
                NavigationLink("Payouts", value: PayoutsPreviewRoute.payouts)
            }
            .navigationTitle("Expert")
            .navigationDestination(for: PayoutsPreviewRoute.self) { _ in
                PayoutsView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Payouts") {
    PayoutsPreviewHarness(viewModel: .previewSeed())
        .preferredColorScheme(.dark)
}

#Preview("Below Minimum") {
    PayoutsPreviewHarness(
        viewModel: .previewSeed(
            summary: PayoutSummaryData(
                availableAmount: 1200,
                pendingAmount: 8000,
                currency: "USD",
                nextPayoutDate: "2026-07-15",
                payoutMethod: "bank_transfer",
                canWithdraw: false,
                minWithdrawableAmount: 5000
            )
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Onboarding Required") {
    PayoutsPreviewHarness(
        viewModel: .previewSeed(summary: nil, onboardingRequired: true)
    )
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return LiveFetchPayoutsPreviewHarness()
        .preferredColorScheme(.dark)
}
