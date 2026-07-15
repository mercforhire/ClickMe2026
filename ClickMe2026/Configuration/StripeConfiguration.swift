//
//  StripeConfiguration.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

#if canImport(StripePaymentSheet)
import StripePaymentSheet
#endif

/// Bootstrap for the Stripe SDK. Called once at app launch from
/// `ClickMe2026AppDelegate`. Guarded by `canImport(StripePaymentSheet)` so
/// the app keeps compiling until the `stripe-ios` SPM package is added to
/// the target — after that, no code changes needed here.
enum StripeConfiguration {

    static func configure() {
        #if canImport(StripePaymentSheet)
        let key = AppEnvironment.current.stripePublishableKey
        guard !key.contains("REPLACE_ME") else {
            assertionFailure("StripePublishableKey in Environments.plist has not been set for env '\(AppEnvironment.current.name)'.")
            return
        }
        STPAPIClient.shared.publishableKey = key
        #else
        // Stripe SDK not linked yet — no-op. Add the `stripe-ios` SPM package
        // (product `StripePaymentSheet`) to enable payments.
        #endif
    }
}
