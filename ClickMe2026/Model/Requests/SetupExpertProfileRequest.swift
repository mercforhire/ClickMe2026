//
//  SetupExpertProfileRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `PATCH /expert/profile/setup` — partial save for a single
/// signup step, or the final "publish" call with `setupCompleted: true`.
///
/// Every top-level field is optional; the backend merges only what is
/// sent. `location` is field-level partial (send only the subkeys you
/// want to update).
///
/// `languages` and `expertiseTags` are destructive when sent: `[]` clears
/// the record. Omit the key to leave existing values untouched.
///
/// `setupCompleted` is one-way — the server only honors `true`. Sending
/// `false` is a no-op; the flag is server-managed the rest of the time.
///
/// Historical: an `hourly_rate` field previously lived here — dropped
/// when the backend removed account-level rates in favor of per-topic
/// pricing.
struct SetupExpertProfileRequest: Encodable {
    struct Location: Encodable {
        var city: String?
        var provinceState: String?
        var countryCode: String?
    }

    var firstName: String?
    var location: Location?
    var timezone: String?
    var languages: [String]?
    var expertiseTags: [String]?
    var setupCompleted: Bool?
}
