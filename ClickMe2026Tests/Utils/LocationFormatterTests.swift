//
//  LocationFormatterTests.swift
//  ClickMe2026Tests
//
//  D-06: one location label for the whole app. Province/state is optional,
//  so an empty, whitespace-only or missing province reads "City, Country"
//  with no stray comma.
//

import Testing
@testable import ClickMe2026

@MainActor
@Suite("Location formatter")
struct LocationFormatterTests {

    @Test("An empty, blank or missing province leaves no stray separator", arguments: ["", "   ", "\n", nil as String?])
    func absentProvince(province: String?) {
        #expect(LocationFormatter.format(city: "Toronto", province: province, country: "CAN") == "Toronto, Canada")
    }

    @Test("A province sits between the city and the country")
    func withProvince() {
        #expect(LocationFormatter.format(city: "Toronto", province: "ON", country: "CAN") == "Toronto, ON, Canada")
    }

    @Test("Parts are trimmed and an alpha-2 country code is named")
    func trimsAndNormalizesCountry() {
        #expect(LocationFormatter.format(city: " Toronto ", province: "ON", country: "ca") == "Toronto, ON, Canada")
    }

    @Test("An unknown country code is shown as given")
    func unknownCountryShownAsGiven() {
        #expect(LocationFormatter.format(city: "", province: "", country: "Atlantis") == "Atlantis")
    }

    @Test("Missing city drops cleanly")
    func missingCity() {
        #expect(LocationFormatter.format(city: nil, province: "ON", country: "CAN") == "ON, Canada")
        #expect(LocationFormatter.format(city: "  ", province: "", country: "USA") == "United States")
    }

    @Test("Nothing to show is nil", arguments: [
        (nil as String?, nil as String?, nil as String?),
        ("  ", "", ""),
        ("", nil, "   "),
    ])
    func nothingIsNil(city: String?, province: String?, country: String?) {
        #expect(LocationFormatter.format(city: city, province: province, country: country) == nil)
    }
}
