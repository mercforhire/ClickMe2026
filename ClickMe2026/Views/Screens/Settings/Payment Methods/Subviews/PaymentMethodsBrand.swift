//
//  PaymentMethodsBrand.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum PaymentMethodsBrand {
    static let bg = Color(red: 0.055, green: 0.055, blue: 0.070)
    static let cardBg = Color(red: 0.095, green: 0.100, blue: 0.120)
    static let rowBg = Color(red: 0.110, green: 0.115, blue: 0.135)
    static let rowDivider = Color(red: 0.160, green: 0.165, blue: 0.190)
    static let brandGreen = Brand.primary
    static let onSurface = Brand.onSurface
    static let onSurfaceVar = Color(red: 0.580, green: 0.630, blue: 0.610)
    static let onPrimary = Brand.onPrimary
    static let destructive = Color(red: 0.95, green: 0.36, blue: 0.36)
}

// MARK: - Card brand → display copy + icon

enum PaymentMethodBrandDisplay {
    /// Turns Stripe's lowercase brand string into a display name
    /// (e.g. `"visa"` → `"Visa"`). Unknown brands render as "Card" so
    /// the row never shows a raw enum-looking value to the user.
    static func name(_ brand: String) -> String {
        switch brand.lowercased() {
        case "visa":       return "Visa"
        case "mastercard": return "Mastercard"
        case "amex":       return "American Express"
        case "discover":   return "Discover"
        case "diners":     return "Diners Club"
        case "jcb":        return "JCB"
        case "unionpay":   return "UnionPay"
        default:           return "Card"
        }
    }

    /// SF Symbol for the card brand. Apple ships branded card symbols
    /// only for a handful of brands; everything else gets the generic
    /// `creditcard.fill`.
    static func systemImage(_ brand: String) -> String {
        // Apple's SF Symbol set doesn't include brand-specific card
        // marks in the public catalog — so we render `creditcard.fill`
        // for every brand and let the display name carry brand identity.
        // If we ever bundle brand SVGs, swap this to look them up.
        _ = brand
        return "creditcard.fill"
    }
}
