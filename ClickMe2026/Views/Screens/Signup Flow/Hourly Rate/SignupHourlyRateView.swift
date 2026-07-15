//
//  SignupHourlyRateView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Hourly Rate navigation routes

private enum RateRoute: Hashable {
    case currencySelection
}

// MARK: - Set Hourly Rate View

struct ClickMeSetHourlyRateView: View {

    @StateObject private var viewModel: SignupHourlyRateViewModel

    // UI-only state
    @FocusState private var rateFocused: Bool

    // MARK: Callbacks

    var onNext: (Int, String) -> Void // (rate, currency)
    var onBack: () -> Void

    // MARK: Design tokens — Luminous Dark

    private let bg = Color(red: 0.035, green: 0.060, blue: 0.040) // dark green-black
    private let cardBg = Color(red: 0.065, green: 0.105, blue: 0.075) // slightly lighter green
    private let cardBorder = Color(red: 0.160, green: 0.340, blue: 0.210)
    private let currBg = Color(red: 0.045, green: 0.075, byte: 0.055)
    private let currBorder = Color(red: 0.130, green: 0.280, byte: 0.175)
    private let brandGreen = Brand.primary
    private let onSurface = Brand.onSurface
    private let onSurfaceVar = Color(red: 0.580, green: 0.700, blue: 0.630)
    private let onPrimary = Brand.onPrimary

    // MARK: Init

    init(
        viewModel: SignupHourlyRateViewModel = SignupHourlyRateViewModel(),
        onNext: @escaping (Int, String) -> Void = { _, _ in },
        onBack: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNext = onNext
        self.onBack = onBack
    }

    /// Runtime init that binds directly to the shared `SignupAccumulator`
    /// so rate + currency propagate to the final Publish step.
    init(
        accumulator: SignupAccumulator,
        onNext: @escaping (Int, String) -> Void = { _, _ in },
        onBack: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: SignupHourlyRateViewModel(accumulator: accumulator),
            onNext: onNext,
            onBack: onBack
        )
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                rateCard
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Text("This rate will be applied to all bookings. You can adjust it later in your profile settings.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                Spacer()

                nextButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Set Hourly Rate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture { rateFocused = false }
        .navigationDestination(for: RateRoute.self) { route in
            switch route {
            case .currencySelection:
                ClickMeCurrencySelectionView(
                    initialCurrency: viewModel.currency,
                    onSelect: { item in
                        viewModel.selectCurrency(item.code)
                    }
                )
            }
        }
    }

    // MARK: - Rate card

    private var rateCard: some View {
        HStack(spacing: 0) {
            Text("$")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)
                .shadow(color: brandGreen.opacity(0.30), radius: 6)
                .padding(.leading, 22)
                .padding(.trailing, 8)

            Spacer()

            ZStack {
                // Invisible actual TextField
                TextField("0", text: $viewModel.rateString)
                    .keyboardType(.numberPad)
                    .focused($rateFocused)
                    .foregroundColor(.clear)
                    .tint(.clear)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: viewModel.rateString) {
                        viewModel.sanitizeRateString()
                    }

                Text(viewModel.rateString.isEmpty ? "0" : viewModel.rateString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(onSurface)
                    .shadow(color: brandGreen.opacity(0.30), radius: 8)
                    .onTapGesture { rateFocused = true }
            }

            Spacer()

            NavigationLink(value: RateRoute.currencySelection) {
                HStack(spacing: 5) {
                    Text(viewModel.currency)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(onSurface)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(onSurfaceVar)
                }
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(currBg)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(currBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
        }
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(brandGreen.opacity(0.55), lineWidth: 1.5)
                )
        )
        .background(
            // Outer glow — extends slightly beyond the card edges
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(brandGreen.opacity(0.08))
                .blur(radius: 12)
                .padding(-6)
        )
    }

    // MARK: - Next button

    private var nextButton: some View {
        Button {
            rateFocused = false
            viewModel.commitToAccumulator()
            onNext(viewModel.rateValue, viewModel.currency)
        } label: {
            Text("Next")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    Capsule()
                        .fill(brandGreen)
                        .shadow(color: brandGreen.opacity(0.60), radius: 22, x: 0, y: 6)
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Color helper

private extension Color {
    init(red: Double, green: Double, byte blue: Double, opacity: Double = 1.0) {
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - Previews

#Preview("Set Hourly Rate") {
    PreviewNavHarness(parentText: "Complete your profile", navTitle: "Profile setup", rowTitle: "Set hourly rate") {
        ClickMeSetHourlyRateView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Rate filled") {
    PreviewNavHarness(parentText: "Complete your profile", navTitle: "Profile setup", rowTitle: "Set hourly rate") {
        ClickMeSetHourlyRateView(
            viewModel: SignupHourlyRateViewModel(rateString: "75", currency: "EUR"),
            onNext: { rate, currency in
                print("Rate: \(rate) \(currency)")
            }
        )
    }
    .preferredColorScheme(.dark)
}
