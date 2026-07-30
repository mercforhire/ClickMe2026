//
//  PaymentMethodsData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `GET /me/payment-methods`. Server always returns
/// an array (never null) — empty when the user has no Stripe Customer or
/// no cards attached yet.
struct PaymentMethodsData: Decodable {
    let paymentMethods: [PaymentMethodItem]
}
