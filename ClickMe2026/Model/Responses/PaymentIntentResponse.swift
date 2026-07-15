//
//  PaymentIntentResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// BARE payment intent response — returned directly as the HTTP 200 body with
/// NO `{ status, data }` success envelope. Code-as-is; the only booking endpoint
/// that deviates from the standard envelope.
struct PaymentIntentResponse: Decodable {
    struct Summary: Decodable {
        let subtotal: Double
        let discount: Double
        let total: Double
    }

    let paymentIntentId: String
    let clientSecret: String
    let totalAmount: Double
    let currency: String
    let summary: Summary
}
