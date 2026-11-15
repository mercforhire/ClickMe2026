//
//  ProfileSettingsSnapshotTests.swift
//  ClickMe2026Tests
//
//  G-05-6: a Profile Settings save sends only the groups that changed and never
//  an empty first or last name (the backend schema has min(1) on both). These
//  rows pin the pure rules: group selection, name handling, country
//  normalization, the languages rule (A9), the province rule (D-07) and the
//  merge that moves the baseline after a successful save. No network.
//

import Testing
@testable import ClickMe2026

@MainActor
@Suite("Profile settings snapshot")
struct ProfileSettingsSnapshotTests {

    // MARK: - Fixtures

    /// A fully filled profile; each row overrides only what it edits.
    private static func snapshot(
        firstName: String = "Ada",
        lastName: String = "Lovelace",
        bio: String = "Hello",
        jobTitle: String = "Engineer",
        company: String = "Analytical",
        city: String = "Toronto",
        stateProvince: String = "ON",
        country: String = "CAN",
        languageIds: [String] = ["en"],
        customLanguages: [String] = ["Klingon"]
    ) -> ProfileSettingsSnapshot {
        ProfileSettingsSnapshot(
            firstName: firstName, lastName: lastName, bio: bio,
            jobTitle: jobTitle, company: company,
            city: city, stateProvince: stateProvince, country: country,
            languageIds: languageIds, customLanguages: customLanguages
        )
    }

    /// The shape signup leaves behind: both names empty.
    private static let emptyNames = snapshot(firstName: "", lastName: "")

    // MARK: - Nothing changed

    @Test("Equal snapshots produce no body")
    func equalSnapshotsSendNothing() {
        #expect(Self.snapshot().patch(from: Self.snapshot()) == nil)
    }

    @Test("An edit that only adds surrounding spaces sends nothing")
    func surroundingSpacesAreNotAChange() {
        let current = Self.snapshot(firstName: " Ada ", bio: "  Hello ", city: " Toronto")
        #expect(current.patch(from: Self.snapshot()) == nil)
    }

    // MARK: - G-05-6: empty names are never sent

    @Test("Empty-name baseline, province edited: only the location group goes out")
    func provinceEditOnEmptyNameProfile() throws {
        let baseline = Self.snapshot(firstName: "", lastName: "")
        let current = Self.snapshot(firstName: "", lastName: "", stateProvince: "")

        let body = try #require(current.patch(from: baseline))

        #expect(body.basic == nil)
        #expect(body.professional == nil)
        #expect(body.languages == nil)
        let location = try #require(body.location)
        #expect(location.city == "Toronto")
        #expect(location.stateProvince == "")
        #expect(location.countryCode == "CAN")
    }

    @Test("Empty-name baseline, bio edited: basic carries the bio and no name key")
    func bioEditOnEmptyNameProfile() throws {
        let baseline = Self.emptyNames
        let current = Self.snapshot(firstName: "", lastName: "", bio: "New bio")

        let body = try #require(current.patch(from: baseline))

        let basic = try #require(body.basic)
        #expect(basic.firstName == nil)
        #expect(basic.lastName == nil)
        #expect(basic.bio == "New bio")
        #expect(body.location == nil)
    }

    @Test("First name set, last name empty (published iOS expert): bio edit sends first_name and bio only")
    func bioEditOnFirstNameOnlyProfile() throws {
        let baseline = Self.snapshot(lastName: "")
        let current = Self.snapshot(lastName: "", bio: "New bio")

        let basic = try #require(current.patch(from: baseline)?.basic)

        #expect(basic.firstName == "Ada")
        #expect(basic.lastName == nil)
        #expect(basic.bio == "New bio")
    }

    @Test("Empty-name baseline, last name typed: basic carries the last name only")
    func lastNameTypedOnEmptyNameProfile() throws {
        let baseline = Self.emptyNames
        let current = Self.snapshot(firstName: "", lastName: "Lovelace")

        let basic = try #require(current.patch(from: baseline)?.basic)

        #expect(basic.firstName == nil)
        #expect(basic.lastName == "Lovelace")
    }

    // MARK: - A set name the user clears is held

    @Test("A cleared first name with nothing else changed sends nothing")
    func clearedFirstNameIsHeld() {
        let current = Self.snapshot(firstName: "")
        #expect(current.patch(from: Self.snapshot()) == nil)
    }

    @Test("A cleared first name does not block another changed group")
    func clearedFirstNameDoesNotBlockCityEdit() throws {
        let current = Self.snapshot(firstName: "", city: "Ottawa")

        let body = try #require(current.patch(from: Self.snapshot()))

        #expect(body.basic == nil)
        #expect(body.location?.city == "Ottawa")
    }

    // MARK: - D-07: a cleared State/Province is an empty string

    @Test("Complete baseline, State/Province cleared: location carries an empty string, never nil")
    func clearedProvinceIsEmptyString() throws {
        let current = Self.snapshot(stateProvince: "")

        let location = try #require(current.patch(from: Self.snapshot())?.location)

        #expect(location.stateProvince == "")
    }

    // MARK: - Country

    @Test("An empty current country never counts as a change")
    func emptyCountryIsNotAChange() {
        let current = Self.snapshot(country: "")
        #expect(current.patch(from: Self.snapshot(country: "CAN")) == nil)
    }

    @Test("An unknown country never counts as a change")
    func unknownCountryIsNotAChange() {
        let current = Self.snapshot(country: "ZZZ")
        #expect(current.patch(from: Self.snapshot(country: "CAN")) == nil)
    }

    @Test("A different known country sends the normalized alpha-3 code")
    func changedCountrySendsCode() throws {
        let current = Self.snapshot(country: "USA")

        let location = try #require(current.patch(from: Self.snapshot(country: "CAN"))?.location)

        #expect(location.countryCode == "USA")
    }

    // MARK: - Professional

    @Test("A company edit sends the professional group whole")
    func companyEditSendsProfessionalWhole() throws {
        let current = Self.snapshot(company: "Babbage & Co")

        let body = try #require(current.patch(from: Self.snapshot()))

        #expect(body.professional?.jobTitle == "Engineer")
        #expect(body.professional?.company == "Babbage & Co")
        #expect(body.basic == nil)
        #expect(body.location == nil)
    }

    // MARK: - Languages (A9, T-05-35)

    @Test("Reordered language ids send the new order with the custom languages")
    func reorderedLanguagesAreSent() throws {
        let baseline = Self.snapshot(languageIds: ["en", "es"])
        let current = Self.snapshot(languageIds: ["es", "en"])

        let languages = try #require(current.patch(from: baseline)?.languages)

        #expect(languages.languageIds == ["es", "en"])
        #expect(languages.customLanguages == ["Klingon"])
    }

    @Test("Ids emptied while a custom language remains still saves, with the customs")
    func emptyIdsWithCustomsAreSent() throws {
        let current = Self.snapshot(languageIds: [])

        let languages = try #require(current.patch(from: Self.snapshot())?.languages)

        #expect(languages.languageIds == [])
        #expect(languages.customLanguages == ["Klingon"])
    }

    @Test("Ids emptied with no custom language never sends a languages group")
    func zeroLanguagesAreNeverSent() {
        let baseline = Self.snapshot(languageIds: ["en"], customLanguages: [])
        let current = Self.snapshot(languageIds: [], customLanguages: [])
        #expect(current.patch(from: baseline) == nil)
    }

    @Test("Unchanged language ids leave the languages group out")
    func unchangedLanguagesAreLeftOut() throws {
        let current = Self.snapshot(bio: "New bio")
        let body = try #require(current.patch(from: Self.snapshot()))
        #expect(body.languages == nil)
    }

    // MARK: - Merge

    @Test("Merging a location-only body updates the location and keeps the baseline names")
    func mergingLocationKeepsHeldName() throws {
        let baseline = Self.snapshot()
        let current = Self.snapshot(firstName: "", city: "Ottawa")
        let sent = try #require(current.patch(from: baseline))

        let merged = baseline.merging(sent)

        #expect(merged.city == "Ottawa")
        #expect(merged.firstName == "Ada")
        #expect(merged.lastName == "Lovelace")
        #expect(merged.bio == "Hello")
    }

    @Test("Merging a languages body replaces the ids and the customs")
    func mergingLanguagesReplacesBoth() throws {
        let baseline = Self.snapshot(languageIds: ["en"], customLanguages: ["Klingon"])
        let current = Self.snapshot(languageIds: ["fr", "en"], customLanguages: ["Klingon"])
        let sent = try #require(current.patch(from: baseline))

        let merged = baseline.merging(sent)

        #expect(merged.languageIds == ["fr", "en"])
        #expect(merged.customLanguages == ["Klingon"])
    }

    @Test("After a merge the same edit produces no second body")
    func mergeMakesTheSavedEditIdempotent() throws {
        let baseline = Self.emptyNames
        let current = Self.snapshot(firstName: "", lastName: "", stateProvince: "")
        let sent = try #require(current.patch(from: baseline))

        #expect(current.patch(from: baseline.merging(sent)) == nil)
    }

    // MARK: - Name errors

    @Test("A cleared first name reports the required copy")
    func firstNameErrorWhenCleared() {
        let current = Self.snapshot(firstName: "")
        #expect(current.firstNameError(from: Self.snapshot()) == "Please enter your first name.")
    }

    @Test("A first name that was never set reports no error")
    func firstNameNoErrorWhenNeverSet() {
        let current = Self.snapshot(firstName: "")
        #expect(current.firstNameError(from: Self.snapshot(firstName: "")) == nil)
    }

    @Test("A filled first name reports no error")
    func firstNameNoErrorWhenFilled() {
        #expect(Self.snapshot().firstNameError(from: Self.snapshot()) == nil)
    }

    @Test("A cleared last name reports the required copy")
    func lastNameErrorWhenCleared() {
        let current = Self.snapshot(lastName: "")
        #expect(current.lastNameError(from: Self.snapshot()) == "Please enter your last name.")
    }

    @Test("A last name that was never set reports no error")
    func lastNameNoErrorWhenNeverSet() {
        let current = Self.snapshot(lastName: "")
        #expect(current.lastNameError(from: Self.snapshot(lastName: "")) == nil)
    }
}
