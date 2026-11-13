//
//  LocationFormatter.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The one place a location label is built, for the signup review and the
/// expert-side client profile (D-06).
///
/// Province/state is optional (D-05), so every part is trimmed and an empty,
/// whitespace-only or missing part is dropped before joining. An absent
/// province therefore reads "City, Country" with no stray comma.
enum LocationFormatter {

    /// - Parameters:
    ///   - city: City, or nil.
    ///   - province: Province/state, or nil. Optional by design.
    ///   - country: A country code (alpha-3, or alpha-2 from legacy data), shown
    ///     as the country's name. An unrecognised value is shown as given.
    /// - Returns: "City, Province, Country" with absent parts removed, or nil
    ///   when nothing is left to show.
    static func format(city: String?, province: String?, country: String?) -> String? {
        let countryName = country.flatMap { raw -> String? in
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return Countries.normalize(trimmed).flatMap(Countries.find(byCode:))?.name ?? trimmed
        }
        let parts = [city, province, countryName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
