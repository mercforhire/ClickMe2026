//
//  ClickMeAPI+PaymentMethods.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

// MARK: - Client-side saved payment methods
//
// Backs the "Payment Methods" screen in client settings. Cards are
// attached to the caller's Stripe Customer via a SetupIntent flow —
// the client never sees the Stripe secret key, and no card data ever
// hits our servers (PaymentSheet tokenizes directly against Stripe).

extension ClickMeAPI {

    /// `GET /me/payment-methods` — returns the caller's saved cards.
    /// Always an array; empty when the user has no Stripe Customer yet.
    func getPaymentMethods() async throws -> SuccessDataResponse<PaymentMethodsData> {
        try await service.httpRequest(
            url: url(.getPaymentMethods),
            method: .get,
            parameters: nil
        )
    }

    /// `POST /me/payment-methods/setup-intent` — mints a Stripe
    /// SetupIntent so the client can present PaymentSheet in setup mode
    /// and attach a new card without charging. Returns everything
    /// PaymentSheet's customer config needs: `clientSecret`,
    /// `customerId`, and a short-lived `ephemeralKey`.
    ///
    /// Idempotent per user in the sense that repeat calls just mint a
    /// new SetupIntent — the underlying Stripe Customer is created once
    /// on the first call and reused thereafter.
    func createPaymentMethodSetupIntent() async throws -> SuccessDataResponse<PaymentMethodSetupData> {
        try await service.httpRequest(
            url: url(.createPaymentMethodSetupIntent),
            method: .post,
            parameters: [:]
        )
    }

    /// `DELETE /me/payment-methods/:id` — detaches a card from the
    /// Stripe Customer. If the removed card was the default, the
    /// server clears `invoice_settings.default_payment_method` too.
    /// 404s when the id doesn't belong to the caller.
    func deletePaymentMethod(paymentMethodId: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.deletePaymentMethod, stringId: paymentMethodId),
            method: .delete,
            parameters: nil
        )
    }

    /// `PATCH /me/payment-methods/:id/default` — marks the given card
    /// as the Stripe Customer's default. Only one card can be default
    /// at a time; the server flips the previous default off atomically.
    func setDefaultPaymentMethod(paymentMethodId: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.setDefaultPaymentMethod, stringId: paymentMethodId),
            method: .patch,
            parameters: [:]
        )
    }
}
