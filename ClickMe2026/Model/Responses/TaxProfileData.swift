//
//  TaxProfileData.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Response payload for `GET /expert/tax-profile`.
///
/// The server never echoes the TIN back — `tinOnFile` says whether one
/// is stored. Legal name, address, DOB, and financial account
/// identifier come back verbatim.
struct TaxProfileData: Decodable {
    /// Optional so a server that returns `{}` for a brand-new expert
    /// (no tax profile saved) still decodes — defaults to false at the
    /// UI layer.
    let tinOnFile: Bool?
    let legalName: String?
    let address: TaxProfileAddress?
    /// `YYYY-MM-DD` — parsed as a plain string, not `Date`, because
    /// the field is a calendar date, not a timestamp.
    let dob: String?
    let financialAccountIdentifier: String?
}

/// Shared address shape for the tax profile. The backend accepts /
/// returns a nested object under `address` — line1 + city + region +
/// postal + country cover the fields Stripe's connected-account KYC
/// requires for CA. All fields are optional on the wire so a
/// partially-populated profile (e.g. an expert who hasn't finished
/// the form yet) doesn't fail decoding — the POST enforces the
/// canonical required set.
struct TaxProfileAddress: Codable {
    let line1: String?
    let line2: String?
    let city: String?
    let region: String?
    let postalCode: String?
    /// ISO 3166-1 alpha-2 country code (e.g. `"CA"`).
    let country: String?
}
