//
//  SaveTaxProfileRequest.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Request body for `POST /expert/tax-profile`. `tin` and
/// `financialAccountIdentifier` are optional; when `tin` is nil the
/// server returns `saved: false, tin_required: true` and doesn't
/// persist the rest — matches the doc's deferred-save semantics.
struct SaveTaxProfileRequest: Encodable {
    let legalName: String
    let address: TaxProfileAddress
    /// `YYYY-MM-DD`.
    let dob: String
    let tin: String?
    let financialAccountIdentifier: String?
}
