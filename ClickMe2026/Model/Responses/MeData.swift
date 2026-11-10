//
//  MeData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// `GET /me` — authenticated user's identity from the verified JWT payload.
///
/// `roles` is a set — a user with `["client", "expert"]` can hit both
/// client- and expert-scoped endpoints. Every account has `client` by
/// default; experts additionally have `expert`.
struct MeData: Decodable {
    let id: UUID
    let email: String
    let roles: [UserRole]
    /// Operator-configurable platform limits. Backend spec explicitly
    /// says **don't cache** — re-fetch with `/me` on each launch since
    /// values (including a global kill-switch) can change without an
    /// app release. `nil` when the backend predates the rollout;
    /// callers must degrade to server-authoritative validation
    /// (`PRICE_BELOW_MINIMUM` on save) rather than blocking the save.
    let pricingLimits: PricingLimits?
}

/// Platform-wide limits carried by `GET /me`. Holds `min_session_amount`
/// and `allowed_currencies`; more limits can join this container without
/// changing call sites.
struct PricingLimits: Decodable {
    /// Uppercase ISO-4217 codes a topic may be priced in, in display order
    /// (`["CAD", "USD"]` today). Feeds the topic editor's currency picker.
    /// Optional because a backend that predates backend Phase 34 omits it;
    /// callers fall back to `[minSessionAmount.defaultCurrency]`. See
    /// `docs/ios/USD-TOPIC-PRICING.md` §1 in the backend repo.
    let allowedCurrencies: [String]?
    let minSessionAmount: MinSessionAmount
}

/// Per-currency minimum session price, in **integer minor units**
/// (same unit as `price.amount` on a topic). Free topics are exempt
/// per §4 of the spec — never apply this to a `is_free` topic.
///
/// Lookup rule: `byCurrency[topicCurrency] ?? defaultMinorUnits`.
/// The `defaultCurrency` field replaces the old hard-coded
/// `TopicEditorViewModel.defaultCurrency = "CAD"` — read it here
/// instead so operator changes propagate without an app release.
struct MinSessionAmount: Decodable {
    /// Uppercase ISO-4217 code → floor in minor units. Floors are still
    /// published for every seeded currency (8 today: USD, EUR, GBP, CAD,
    /// AUD, JPY, INR, CHF), but only the codes in
    /// `PricingLimits.allowedCurrencies` may price a topic. Look up with
    /// the topic's own currency; fall back to `defaultMinorUnits` for
    /// anything not in the map.
    let byCurrency: [String: Int]
    /// Fallback floor when the selected currency isn't a key in
    /// `byCurrency`. Use this rather than skipping validation.
    let defaultMinorUnits: Int
    /// Currency the backend assumes when a topic carries no currency.
    /// `"CAD"` today, but read from the wire rather than hard-coded —
    /// operator-configurable per §1.
    let defaultCurrency: String

    /// Returns the floor for `currency` (or the default when the map
    /// misses), in minor units. `currency` should be an uppercase
    /// ISO-4217 code.
    func minMinorUnits(for currency: String) -> Int {
        byCurrency[currency.uppercased()] ?? defaultMinorUnits
    }
}
