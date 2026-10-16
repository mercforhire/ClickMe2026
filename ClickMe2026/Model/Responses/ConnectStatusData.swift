//
//  ConnectStatusData.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Response payload for `GET /expert/connect/status`.
///
/// Re-fetched live from Stripe on every call — the server never caches
/// it. Used to gate the expert's "you can accept bookings" state and to
/// prompt reopening onboarding when Stripe still has requirements
/// outstanding.
struct ConnectStatusData: Decodable {
    /// True when Stripe has cleared the account to accept payments.
    /// The booking gate (§3.5 in the Stripe integration doc) refuses
    /// experts who aren't `charges_enabled`.
    let chargesEnabled: Bool

    /// Stripe requirement strings still outstanding on the account
    /// (empty when fully verified). Non-empty → present a "finish
    /// verification" CTA that reopens onboarding via
    /// `POST /expert/connect/refresh-link`.
    let currentlyDue: [String]
}
