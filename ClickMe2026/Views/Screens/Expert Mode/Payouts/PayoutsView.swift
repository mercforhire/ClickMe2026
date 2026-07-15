//
//  PayoutsView.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
    @Environment(\.openURL) private var openURL

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
        .onChange(of: viewModel.connectOnboardingURL) { _, url in
            guard let url else { return }
            openURL(url)
            viewModel.connectOnboardingURL = nil
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
                    payoutScheduleNote
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

    // MARK: - Payout schedule note

    private var payoutScheduleNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(onSurfaceVar)
            Text("Your available balance is transferred to your bank automatically on the schedule above.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
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

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Payouts") {
        PayoutsView()
    }
    .preferredColorScheme(.dark)
}
