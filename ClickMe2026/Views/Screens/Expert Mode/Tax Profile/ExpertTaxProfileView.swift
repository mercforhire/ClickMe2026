//
//  ExpertTaxProfileView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// "Tax & Payout Info" — CRA / Stripe Connect KYC form. Mirrors the
/// visual language of `ExpertProfileSettingsView` (same field style,
/// same section rhythm). TIN is treated as sensitive: the server
/// never echoes it, we only send it on save, and we clear the local
/// value after a successful persist.
struct ExpertTaxProfileView: View {

    @StateObject private var viewModel: ExpertTaxProfileViewModel

    init(viewModel: ExpertTaxProfileViewModel = ExpertTaxProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .navigationTitle("Tax & Payout Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .keyboardDismissToolbar()
        .alert(
            "Couldn't save tax profile",
            isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            ),
            presenting: viewModel.saveError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert(
            "Tax profile",
            isPresented: Binding(
                get: { viewModel.saveMessage != nil },
                set: { if !$0 { viewModel.saveMessage = nil } }
            ),
            presenting: viewModel.saveMessage
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
            VStack(spacing: 24) {
                intro
                legalSection
                addressSection
                sensitiveSection
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Sections

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Required by Stripe to process your payouts and to meet CRA reporting rules. Your TIN is stored encrypted and is never shown back to you.")
                .font(.brand(.caption))
                .foregroundColor(ProfileSettingsBrand.labelColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Legal identity")
            ProfileLabeledField(label: "Legal name", text: $viewModel.legalName)
            ProfileLabeledField(label: "Date of birth (YYYY-MM-DD)", text: $viewModel.dob, keyboard: .numbersAndPunctuation)
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Address")
            ProfileLabeledField(label: "Street address", text: $viewModel.addressLine1)
            ProfileLabeledField(label: "Apt / suite (optional)", text: $viewModel.addressLine2)
            ProfileLabeledField(label: "City", text: $viewModel.city)
            HStack(spacing: 10) {
                ProfileLabeledField(label: "Province / region", text: $viewModel.region)
                ProfileLabeledField(label: "Postal code", text: $viewModel.postalCode)
            }
            ProfileLabeledField(label: "Country", text: $viewModel.country)
        }
    }

    private var sensitiveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Tax identification")
            tinField
            ProfileLabeledField(
                label: "Financial account (optional)",
                text: $viewModel.financialAccountIdentifier
            )
        }
    }

    /// TIN + on-file pill. Value is entered fresh every time — the
    /// server never returns the stored TIN, so there's nothing to
    /// pre-populate.
    private var tinField: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProfileLabeledField(
                label: "TIN (SIN / BN)",
                text: $viewModel.tin,
                keyboard: .numbersAndPunctuation
            )
            if viewModel.tinOnFile {
                Label("TIN on file", systemImage: "lock.shield.fill")
                    .font(.brand(.caption2, weight: .semibold))
                    .foregroundColor(Brand.primary)
            } else {
                Text("Optional now — required before Stripe releases your payouts.")
                    .font(.brand(.caption2))
                    .foregroundColor(ProfileSettingsBrand.labelColor)
            }
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(Brand.onPrimary)
                        .controlSize(.small)
                    Text("Saving…")
                        .font(.brand(.callout, weight: .bold))
                } else {
                    Text("Save")
                        .font(.brand(.callout, weight: .bold))
                }
            }
            .foregroundColor(Brand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule().fill(viewModel.canSave ? Brand.primary : Brand.primary.opacity(0.4))
            )
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
    }

    // MARK: - Section header helper

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.brand(.caption, weight: .semibold))
            .tracking(1.4)
            .foregroundColor(ProfileSettingsBrand.labelColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading / error

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading tax profile…")
                .font(.brand(.caption))
                .foregroundColor(ProfileSettingsBrand.labelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(ProfileSettingsBrand.labelColor)
            Text("Couldn't load tax profile")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(ProfileSettingsBrand.labelColor)
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
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
