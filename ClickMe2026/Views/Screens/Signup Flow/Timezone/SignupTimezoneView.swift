//
//  SignupTimezoneView.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Timezone Picker (signup step)

struct SignupTimezoneView: View {

    @StateObject private var viewModel: SignupTimezoneViewModel

    var onNext: () -> Void

    // MARK: Design tokens — reuse the Basic Info palette for continuity
    private let bg          = Color(red: 0.075, green: 0.075, blue: 0.075)
    private let cardBg      = Color(red: 0.118, green: 0.118, blue: 0.118)
    private let cardBorder  = Color(red: 0.200, green: 0.200, blue: 0.200)
    private let brandGreen  = Color(red: 0.267, green: 0.965, blue: 0.592)
    private let onSurface   = Color(red: 0.898, green: 0.886, blue: 0.882)
    private let onSurfaceVar = Color(red: 0.60, green: 0.68, blue: 0.62)
    private let onPrimary   = Color.black

    // MARK: Init

    init(
        viewModel: SignupTimezoneViewModel = SignupTimezoneViewModel(),
        onNext: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNext = onNext
    }

    /// Runtime init bound to the shared `SignupAccumulator`.
    init(
        accumulator: SignupAccumulator,
        onNext: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: SignupTimezoneViewModel(accumulator: accumulator),
            onNext: onNext
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 24) {
                header
                    .padding(.top, 24)

                pickerCard
                    .padding(.horizontal, 20)

                autoDetectButton
                    .padding(.horizontal, 20)

                Text("We use this to convert booking times to your local time and to align payouts with your day.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                nextButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
            }
        }
        .navigationTitle("Timezone")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Text("Confirm your timezone")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)
                .multilineTextAlignment(.center)
            Text("We auto-detected this from your device.\nChange it if it's wrong.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }

    private var pickerCard: some View {
        Menu {
            ForEach(Timezones.all) { entry in
                Button {
                    viewModel.select(entry)
                } label: {
                    HStack {
                        Text(entry.label)
                        if entry.id == viewModel.timezoneId {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(brandGreen)

                Text(viewModel.timezoneLabel)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(onSurface)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(onSurfaceVar)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var autoDetectButton: some View {
        Button {
            viewModel.autoDetect()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Auto-detect from device")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(brandGreen)
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var nextButton: some View {
        Button {
            onNext()
        } label: {
            Text("Next")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(brandGreen)
                        .shadow(color: brandGreen.opacity(0.45), radius: 14, x: 0, y: 4)
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Preview harness

private enum SignupTimezonePreviewRoute: Hashable { case timezone }

private struct SignupTimezonePreviewHarness: View {
    let viewModel: SignupTimezoneViewModel
    @State private var path: [SignupTimezonePreviewRoute] = [.timezone]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Create account")
                NavigationLink("Timezone", value: SignupTimezonePreviewRoute.timezone)
            }
            .navigationTitle("Signup")
            .navigationDestination(for: SignupTimezonePreviewRoute.self) { _ in
                SignupTimezoneView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Previews

#Preview("Auto-detected") {
    SignupTimezonePreviewHarness(viewModel: SignupTimezoneViewModel())
        .preferredColorScheme(.dark)
}
