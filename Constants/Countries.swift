//
//  Countries.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// A single country entry surfaced by the profile country picker.
///
/// The `code` is the ISO-3166-1 **alpha-3** identifier (e.g. "USA", "CAN")
/// — that's the wire value the backend expects (`x-discrepancy #17` on the
/// UserProfileData docblock).
struct Country: Identifiable, Hashable {
    /// ISO-3166-1 alpha-3.
    let code: String
    let name: String
    var id: String { code }
}

enum Countries {

    /// Curated list of the countries most likely to appear in the profile
    /// picker, sorted alphabetically. Names are pulled from Foundation's
    /// localized region strings so they match the user's system locale.
    ///
    /// Extend `alpha2ToAlpha3` below to add more countries.
    static let all: [Country] = {
        let locale = Locale(identifier: "en_US")
        return alpha2ToAlpha3.compactMap { alpha2, alpha3 -> Country? in
            let name = locale.localizedString(forRegionCode: alpha2) ?? alpha2
            return Country(code: alpha3, name: name)
        }
        .sorted { $0.name < $1.name }
    }()

    /// Looks up a country by its wire (alpha-3) code. `nil` when the code
    /// isn't in the curated list.
    static func find(byCode code: String) -> Country? {
        all.first { $0.code == code }
    }

    /// Reverse map from ISO-3166-1 alpha-2 → alpha-3 for legacy /
    /// mis-seeded values on the wire. Same source-of-truth as `all`.
    private static let alpha2ToAlpha3: [String: String] = [
        "AR": "ARG", "AU": "AUS", "AT": "AUT", "BE": "BEL", "BR": "BRA",
        "CA": "CAN", "CH": "CHE", "CL": "CHL", "CN": "CHN", "CO": "COL",
        "CZ": "CZE", "DE": "DEU", "DK": "DNK", "EG": "EGY", "ES": "ESP",
        "FI": "FIN", "FR": "FRA", "GB": "GBR", "GR": "GRC", "HK": "HKG",
        "HU": "HUN", "ID": "IDN", "IE": "IRL", "IL": "ISR", "IN": "IND",
        "IT": "ITA", "JP": "JPN", "KR": "KOR", "MX": "MEX", "MY": "MYS",
        "NG": "NGA", "NL": "NLD", "NO": "NOR", "NZ": "NZL", "PE": "PER",
        "PH": "PHL", "PL": "POL", "PT": "PRT", "RO": "ROU", "RU": "RUS",
        "SA": "SAU", "SE": "SWE", "SG": "SGP", "TH": "THA", "TR": "TUR",
        "TW": "TWN", "UA": "UKR", "US": "USA", "VN": "VNM", "ZA": "ZAF"
    ]

    /// Normalizes a raw country code from the UI / a pre-fill / a
    /// legacy stored value into the alpha-3 uppercase form the backend
    /// requires. Strips whitespace, uppercases, and converts alpha-2 →
    /// alpha-3. Returns nil when the input is empty or unrecognized so
    /// callers can decide between omitting the field and surfacing an
    /// error.
    static func normalize(_ raw: String) -> String? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleaned.isEmpty else { return nil }
        if cleaned.count == 3, find(byCode: cleaned) != nil {
            return cleaned
        }
        if cleaned.count == 2, let mapped = alpha2ToAlpha3[cleaned] {
            return mapped
        }
        return nil
    }
}
