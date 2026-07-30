//
//  PaymentMethodsSetupSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI
import UIKit

#if canImport(StripePaymentSheet)
import StripePaymentSheet
#endif

/// Attaches the Stripe PaymentSheet in **setup mode** to the Payment
/// Methods screen. When `viewModel.pendingSetup` flips to a populated
/// value (see `PaymentMethodsViewModel.beginAddPaymentMethod`), the
/// modifier presents PaymentSheet with the `setupIntentClientSecret`
/// so the user can save a card without a charge. Result is fed back to
/// the view model via `complete/cancel/failAddPaymentMethod`.
///
/// Guarded by `canImport(StripePaymentSheet)` so the file keeps
/// compiling if the SPM package is ever removed — in that case the
/// modifier surfaces a friendly error instead of hanging.
private struct PaymentMethodsSetupSheetModifier: ViewModifier {
    @ObservedObject var viewModel: PaymentMethodsViewModel

    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.pendingSetup?.clientSecret) { _, newValue in
                guard newValue != nil else { return }
                presentSheet()
            }
    }

    // MARK: - Presentation

    private func presentSheet() {
        #if canImport(StripePaymentSheet)
        guard let setup = viewModel.pendingSetup else {
            viewModel.cancelAddPaymentMethod()
            return
        }
        guard let presenter = Self.topViewController() else {
            viewModel.failAddPaymentMethod("Couldn't present the payment sheet.")
            return
        }

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "ClickMe"
        config.allowsDelayedPaymentMethods = false
        config.customer = .init(
            id: setup.customerId,
            ephemeralKeySecret: setup.ephemeralKey
        )

        let sheet = PaymentSheet(
            setupIntentClientSecret: setup.clientSecret,
            configuration: config
        )

        sheet.present(from: presenter) { result in
            handleResult(result)
        }
        #else
        viewModel.failAddPaymentMethod("Payments are unavailable in this build.")
        #endif
    }

    // MARK: - Result handling

    #if canImport(StripePaymentSheet)
    private func handleResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            // Stripe has attached the PaymentMethod to the Customer.
            // Re-fetch the list so the new card appears.
            Task { await viewModel.completeAddPaymentMethod() }
        case .canceled:
            viewModel.cancelAddPaymentMethod()
        case .failed(let error):
            viewModel.failAddPaymentMethod(error.localizedDescription)
        }
    }
    #endif

    // MARK: - Presenter lookup

    /// Walks the active key window's presentation chain to find the
    /// deepest view controller that can present PaymentSheet modally.
    /// Mirrors the helper in `MakeABookingStripePaymentSheet` — kept
    /// separate rather than shared so each feature can evolve its
    /// PaymentSheet integration independently.
    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension View {
    /// Attaches the Stripe SetupIntent PaymentSheet flow to any view
    /// holding a `PaymentMethodsViewModel`.
    func paymentMethodsSetupSheet(viewModel: PaymentMethodsViewModel) -> some View {
        modifier(PaymentMethodsSetupSheetModifier(viewModel: viewModel))
    }
}
