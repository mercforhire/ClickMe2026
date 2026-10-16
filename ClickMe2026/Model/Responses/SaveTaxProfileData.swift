//
//  SaveTaxProfileData.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Response `data` for `POST /expert/tax-profile`.
///
/// Two shapes rolled into one:
///  * TIN provided → `saved: true, tinRequired: false`.
///  * TIN omitted (deferred) → `saved: false, tinRequired: true`,
///    plus a server `message` hint.
struct SaveTaxProfileData: Decodable {
    let saved: Bool
    let tinRequired: Bool
    let message: String?
}
