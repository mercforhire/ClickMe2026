//
//  MakeABookingStripePaymentSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI
import UIKit

#if canImport(StripePaymentSheet)
import StripePaymentSheet
#endif
#if canImport(StripePayments)
import StripePayments
#endif

/// Path A confirmation flow — the PaymentSheet runs in **setup mode**
/// against a SetupIntent on the platform customer, not against the
/// booking PI. It collects a card into a reusable `pm_…` on the
/// platform customer and hands the id back to the view model. The
/// server then confirms the booking PI on the expert's connected
/// account (the client SDK doesn't have `acct_…` and can't confirm
/// connected-account PIs itself).
///
/// Bonus: SetupIntent-mode confirmation runs 3DS/SCA up-front for
/// fresh cards, so the resulting `pm_…` is pre-authenticated. When
/// the server later confirms the booking PI off-session against that
/// method it won't bounce on fresh-card SCA.
///
/// Two SwiftUI observers on the view model:
///  * `paidStep == .collectingPaymentMethod` → present the sheet in
///    setup mode via `PaymentSheet.FlowController`.
///  * `pendingSCAChallenge != nil` → run 3DS via `STPPaymentHandler`
///    using the `client_secret` (+ `stripe_account`) returned in the
///    402 `PAYMENT_REQUIRES_ACTION` detail (saved-card SCA only —
///    fresh cards already cleared 3DS at SetupIntent confirm above).
///
/// Guarded by `canImport(StripePaymentSheet)` so the file keeps
/// compiling if the SPM package is ever removed — the modifier becomes
/// a no-op observer.
private struct MakeABookingStripePaymentSheetModifier: ViewModifier {
    @ObservedObject var viewModel: MakeABookingViewModel

    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.paidStep) { _, newStep in
                guard newStep == .collectingPaymentMethod else { return }
                presentSheet()
            }
            .onChange(of: viewModel.pendingSCAChallenge) { _, challenge in
                guard let challenge else { return }
                runSCA(challenge)
            }
    }

    // MARK: - Payment method collection (defer-confirm)

    private func presentSheet() {
        #if canImport(StripePaymentSheet)
        guard let secret = viewModel.setupIntentClientSecret else {
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

        // Saved-cards listing — needs the platform customer + a
        // short-lived ephemeral key returned by /me/payment-methods/setup-intent.
        if let customerId = viewModel.stripeCustomerId,
           let ephemeralKey = viewModel.stripeEphemeralKey {
            config.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKey
            )
        }

        // FlowController in **setup mode**: confirmation targets the
        // SetupIntent on the platform customer, so it attaches the card
        // (and runs any 3DS/SCA) without ever touching the booking PI
        // on the expert's connected account. We then read the resulting
        // `pm_…` off the confirmed SetupIntent and hand it to the server
        // for `/bookings/confirm` — which does the real charge-auth on
        // the connected account.
        PaymentSheet.FlowController.create(
            setupIntentClientSecret: secret,
            configuration: config
        ) { result in
            switch result {
            case .failure(let error):
                viewModel.bookingError = error.localizedDescription
                viewModel.cancelPaidBooking()
            case .success(let flowController):
                flowController.presentPaymentOptions(from: presenter) {
                    guard flowController.paymentOption != nil else {
                        // User dismissed without selecting.
                        viewModel.cancelPaidBooking()
                        return
                    }
                    Task { await confirmViaFlow(flowController: flowController, presenter: presenter) }
                }
            }
        }
        #else
        viewModel.bookingError = "Payments are unavailable in this build."
        viewModel.cancelPaidBooking()
        #endif
    }

    #if canImport(StripePaymentSheet)
    /// Runs the FlowController's setup-mode confirm — attaches the
    /// collected card to the platform customer via the SetupIntent, runs
    /// any 3DS as part of that step, then hands the resulting `pm_…` to
    /// the view model. The booking PI itself is never touched
    /// client-side; server `/bookings/confirm` does the connected-
    /// account confirm off-session.
    private func confirmViaFlow(
        flowController: PaymentSheet.FlowController,
        presenter: UIViewController
    ) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            flowController.confirm(from: presenter) { result in
                switch result {
                case .canceled:
                    viewModel.cancelPaidBooking()
                case .failed(let error):
                    viewModel.bookingError = error.localizedDescription
                    viewModel.cancelPaidBooking()
                case .completed:
                    Task {
                        if let pmId = await retrievePaymentMethodId() {
                            await viewModel.completePaidBooking(paymentMethodId: pmId)
                        } else {
                            viewModel.bookingError = "Couldn't read the selected payment method. Please try again."
                            viewModel.cancelPaidBooking()
                        }
                    }
                }
                cont.resume()
            }
        }
    }

    /// Reads the pm_ id off the SetupIntent after Stripe's SDK has
    /// attached it. `paymentMethodID` is populated once the SetupIntent
    /// reaches `succeeded` (which is what a successful setup-mode
    /// confirm produces).
    private func retrievePaymentMethodId() async -> String? {
        guard let secret = viewModel.setupIntentClientSecret else { return nil }
        return await withCheckedContinuation { cont in
            STPAPIClient.shared.retrieveSetupIntent(withClientSecret: secret) { intent, _ in
                cont.resume(returning: intent?.paymentMethodID)
            }
        }
    }
    #endif

    // MARK: - 3DS / SCA challenge

    /// Runs the next-action (3DS) sheet for a PI on a connected account.
    /// The connected account id (`stripe_account`) arrives via the
    /// server's 402 `PAYMENT_REQUIRES_ACTION` detail. Once 3DS is
    /// complete, the server sees the PI as `requires_capture` on the
    /// retry, skips its own confirm, and creates the booking.
    private func runSCA(_ challenge: MakeABookingViewModel.SCAChallenge) {
        #if canImport(StripePaymentSheet) && canImport(StripePayments)
        guard let stripeAccount = challenge.stripeAccount, !stripeAccount.isEmpty else {
            // Backend hasn't shipped detail.stripe_account yet. Without
            // it we can't scope the SDK to the connected account, so
            // 3DS on the PI would fail. Fail loudly to avoid a silent
            // "your card can't be used" state.
            viewModel.cancelSCA(withMessage: "This card needs additional verification, which isn't supported yet. Please try a different card.")
            return
        }
        guard let presenter = Self.topViewController() else {
            viewModel.cancelSCA(withMessage: "Couldn't present the verification sheet.")
            return
        }

        // Scope the shared API client to the connected account for the
        // duration of the challenge, then restore. Stripe's iOS SDK
        // doesn't expose a per-call `stripeAccount` override on
        // `STPPaymentHandler`, and constructing a scoped
        // `STPPaymentHandler` is SPI-only, so the safest documented
        // path is to mutate the shared client's account id.
        let previousAccount = STPAPIClient.shared.stripeAccount
        STPAPIClient.shared.stripeAccount = stripeAccount

        let context = SCAAuthContext(presenter: presenter)
        STPPaymentHandler.sharedHandler.handleNextAction(
            forPayment: challenge.clientSecret,
            with: context,
            returnURL: nil as String?
        ) { status, paymentIntent, error in
            // Restore whatever account (nil in the common case) was
            // scoped before we started, so unrelated Stripe calls
            // aren't accidentally scoped to a connected account.
            STPAPIClient.shared.stripeAccount = previousAccount

            switch status {
            case .succeeded:
                Task {
                    guard let pmId = paymentIntent?.paymentMethodId else {
                        viewModel.cancelSCA(withMessage: "Payment method couldn't be resolved after verification.")
                        return
                    }
                    await viewModel.retryConfirmAfterSCA(paymentMethodId: pmId)
                }
            case .canceled:
                viewModel.cancelSCA()
            case .failed:
                viewModel.cancelSCA(withMessage: error?.localizedDescription ?? "Card verification failed.")
            @unknown default:
                viewModel.cancelSCA(withMessage: "Card verification failed.")
            }
        }
        #else
        viewModel.cancelSCA(withMessage: "Card verification isn't supported in this build.")
        #endif
    }

    #if canImport(StripePayments)
    /// Minimal auth context — hands `STPPaymentHandler` the presenting
    /// UIViewController so it can attach the 3DS web sheet.
    private final class SCAAuthContext: NSObject, STPAuthenticationContext {
        let presenter: UIViewController
        init(presenter: UIViewController) { self.presenter = presenter }
        func authenticationPresentingViewController() -> UIViewController { presenter }
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
