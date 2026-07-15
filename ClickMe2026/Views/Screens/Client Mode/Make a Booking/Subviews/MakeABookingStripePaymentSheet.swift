//
//  MakeABookingStripePaymentSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI
import UIKit

#if canImport(StripePaymentSheet)
import StripePaymentSheet
#endif

/// Presents the Stripe PaymentSheet whenever the view model enters
/// `.awaitingPaymentSheet`, and translates the result back into view-model
/// callbacks (`completePaidBooking(paymentMethodId:)` /
/// `cancelPaidBooking()` / `bookingError`).
///
/// Guarded by `canImport(StripePaymentSheet)` so the file keeps compiling
/// if the SPM package is ever removed — in that case the modifier becomes a
/// no-op observer.
private struct MakeABookingStripePaymentSheetModifier: ViewModifier {
    @ObservedObject var viewModel: MakeABookingViewModel

    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.paidStep) { _, newStep in
                guard newStep == .awaitingPaymentSheet else { return }
                presentSheet()
            }
    }

    // MARK: - Presentation

    private func presentSheet() {
        #if canImport(StripePaymentSheet)
        guard let secret = viewModel.paymentIntentClientSecret else {
            viewModel.cancelPaidBooking()
            return
        }
        guard let presenter = Self.topViewController() else {
            viewModel.bookingError = "Couldn't present the payment sheet."
            viewModel.cancelPaidBooking()
            return
        }

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "ClickMe"
        config.allowsDelayedPaymentMethods = false

        let sheet = PaymentSheet(
            paymentIntentClientSecret: secret,
            configuration: config
        )

        sheet.present(from: presenter) { result in
            handleResult(result)
        }
        #else
        // Stripe SDK not linked. Reset the flow so the UI doesn't hang.
        viewModel.bookingError = "Payments are unavailable in this build."
        viewModel.cancelPaidBooking()
        #endif
    }

    // MARK: - Result handling

    #if canImport(StripePaymentSheet)
    private func handleResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            // Stripe confirmed the PaymentIntent client-side. Fetch it back
            // to recover the paymentMethod.stripeId our server needs.
            Task {
                if let paymentMethodId = await retrievePaymentMethodId() {
                    await viewModel.completePaidBooking(paymentMethodId: paymentMethodId)
                } else {
                    viewModel.bookingError = "Payment succeeded but we couldn't fetch the payment method ID. Contact support with the reference in Stripe."
                    viewModel.cancelPaidBooking()
                }
            }
        case .canceled:
            viewModel.cancelPaidBooking()
        case .failed(let error):
            viewModel.bookingError = error.localizedDescription
            viewModel.cancelPaidBooking()
        }
    }

    private func retrievePaymentMethodId() async -> String? {
        guard let secret = viewModel.paymentIntentClientSecret else { return nil }
        return await withCheckedContinuation { cont in
            STPAPIClient.shared.retrievePaymentIntent(withClientSecret: secret) { intent, _ in
                cont.resume(returning: intent?.paymentMethodId)
            }
        }
    }
    #endif

    // MARK: - Presenter lookup

    /// Walks the active key window's presentation chain to find the
    /// deepest view controller that can present PaymentSheet modally.
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
    /// Attaches the Stripe PaymentSheet flow to any view holding a
    /// `MakeABookingViewModel`.
    func bookingPaymentSheet(viewModel: MakeABookingViewModel) -> some View {
        modifier(MakeABookingStripePaymentSheetModifier(viewModel: viewModel))
    }
}
