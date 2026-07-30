//
//  PaymentMethodsView.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Payment Methods

/// Client-side saved cards. Pushed from the Payment row in
/// `ClientProfileHomeScreen`. Shows a list of saved cards with a
/// default badge + `···` menu (set-default / remove), an Add Payment
/// Method CTA, and a trust-copy footer.
struct PaymentMethodsView: View {

    @StateObject private var viewModel: PaymentMethodsViewModel
    @State private var pendingDelete: PaymentMethodItem?

    init(viewModel: PaymentMethodsViewModel = PaymentMethodsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PaymentMethodsBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PaymentMethodsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .paymentMethodsSetupSheet(viewModel: viewModel)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.apiError != nil },
                set: { if !$0 { viewModel.apiError = nil } }
            ),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert(
            "Remove payment method?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { item in
            Button("Remove", role: .destructive) {
                let toDelete = item
                pendingDelete = nil
                Task { await viewModel.deletePaymentMethod(toDelete) }
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { item in
            Text("\(PaymentMethodBrandDisplay.name(item.brand)) ···· \(item.last4) will no longer be available at checkout.")
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
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
            VStack(spacing: 16) {
                if viewModel.paymentMethods.isEmpty {
                    emptyState
                        .padding(.top, 32)
                } else {
                    savedCardsSection
                }

                addCardButton
                trustCopy
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var savedCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved cards")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
                .padding(.horizontal, 4)

            ForEach(viewModel.paymentMethods) { pm in
                PaymentMethodRow(
                    paymentMethod: pm,
                    isBusy: viewModel.deletingId == pm.id || viewModel.settingDefaultId == pm.id,
                    onSetDefault: { Task { await viewModel.setDefault(pm) } },
                    onDelete: { pendingDelete = pm }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
            Text("No saved cards yet")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(PaymentMethodsBrand.onSurface)
            Text("Add your first card to book faster next time.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private var addCardButton: some View {
        Button {
            Task { await viewModel.beginAddPaymentMethod() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isMintingSetupIntent {
                    ProgressView()
                        .controlSize(.small)
                        .tint(PaymentMethodsBrand.onPrimary)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text("Add Payment Method")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(PaymentMethodsBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(PaymentMethodsBrand.brandGreen))
        }
        .disabled(viewModel.isMintingSetupIntent)
        .buttonStyle(.plain)
    }

    private var trustCopy: some View {
        Text("Cards are securely stored by Stripe. ClickMe never sees your full card number.")
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(PaymentMethodsBrand.onSurface)
            Text("Loading payment methods…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
            Text("Couldn't load payment methods")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(PaymentMethodsBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(PaymentMethodsBrand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(PaymentMethodsBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Payment Methods") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Payment") {
        PaymentMethodsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Payment") {
        PaymentMethodsView(viewModel: .previewSeed(paymentMethods: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Payment") {
        PaymentMethodsView()
    }
    .preferredColorScheme(.dark)
}
