//
//  PaymentMethodSetupData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `POST /me/payment-methods/setup-intent`.
///
/// Everything Stripe's mobile PaymentSheet needs to attach a new card
/// to the caller's Customer without charging. The `clientSecret` is
/// single-use and expires when Stripe garbage-collects the SetupIntent
/// — mint a fresh one each time the user taps "Add Payment Method".
struct PaymentMethodSetupData: Decodable {
    /// SetupIntent client secret (`seti_..._secret_...`). Passed to
    /// `PaymentSheet(setupIntentClientSecret:configuration:)`.
    let clientSecret: String

    /// Stripe Customer id (`cus_...`). Used for the PaymentSheet
    /// customer config so the sheet can list existing saved cards for
    /// this user.
    let customerId: String

    /// Short-lived ephemeral key (`ek_...`) scoped to the customer. Also
    /// consumed by PaymentSheet's customer config.
    let ephemeralKey: String
}
