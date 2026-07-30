//
//  PaymentMethodItem.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single saved payment method returned by `GET /me/payment-methods`.
///
/// Only card-type methods are surfaced in v1 — the server filters
/// `stripe.paymentMethods.list({ type: 'card' })` before returning.
struct PaymentMethodItem: Decodable, Identifiable, Hashable {
    /// Stripe PaymentMethod id (`pm_...`). Used as the primary key when
    /// deleting or setting default. Not a UUID — Stripe issues opaque
    /// prefixed identifiers.
    let id: String

    /// Lowercase Stripe brand string: `"visa"`, `"mastercard"`, `"amex"`,
    /// `"discover"`, `"diners"`, `"jcb"`, `"unionpay"`, `"unknown"`.
    /// Client maps to display strings + brand marks.
    let brand: String

    /// Last four digits of the card. Always four ASCII digits.
    let last4: String

    /// Card expiry month (1–12).
    let expMonth: Int

    /// Card expiry year, four digits (e.g. `2028`).
    let expYear: Int

    /// True when this PM is the customer's
    /// `invoice_settings.default_payment_method`. Server guarantees at
    /// most one row per list carries `true`.
    let isDefault: Bool
}
