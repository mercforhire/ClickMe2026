//
//  ProfileSettingsSnapshot.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-14.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The auto-saved fields of a Profile Settings screen, trimmed, plus the rules
/// that turn a change into a `PATCH /user/profile` body.
///
/// G-05-6: the screens used to send one whole-form body on every edit. Signup
/// stores `""` for both names and no iOS setup step writes a last name, so every
/// save carried `basic.first_name` / `basic.last_name` as `""` and the backend
/// (`min(1)` on both, `userProfile.schema.js`) answered 422 VALIDATION_ERROR,
/// even for an edit that never touched a name. The rules here follow Android's
/// `buildProfilePatch` (only changed groups, a changed group goes out whole and
/// trimmed) and go one step further: an empty name is never sent.
struct ProfileSettingsSnapshot: Equatable {

    static let firstNameRequired = "Please enter your first name."
    static let lastNameRequired = "Please enter your last name."

    let firstName: String
    let lastName: String
    let bio: String
    let jobTitle: String
    let company: String
    let city: String
    let stateProvince: String
    let country: String
    let languageIds: [String]
    let customLanguages: [String]

    /// Every string is stored trimmed of spaces and tabs, the same trim the old
    /// whole-form body used, so an edit that only adds surrounding spaces equals
    /// the baseline.
    init(
        firstName: String = "",
        lastName: String = "",
        bio: String = "",
        jobTitle: String = "",
        company: String = "",
        city: String = "",
        stateProvince: String = "",
        country: String = "",
        languageIds: [String] = [],
        customLanguages: [String] = []
    ) {
        self.firstName = firstName.trimmingCharacters(in: .whitespaces)
        self.lastName = lastName.trimmingCharacters(in: .whitespaces)
        self.bio = bio.trimmingCharacters(in: .whitespaces)
        self.jobTitle = jobTitle.trimmingCharacters(in: .whitespaces)
        self.company = company.trimmingCharacters(in: .whitespaces)
        self.city = city.trimmingCharacters(in: .whitespaces)
        self.stateProvince = stateProvince.trimmingCharacters(in: .whitespaces)
        self.country = country.trimmingCharacters(in: .whitespaces)
        self.languageIds = languageIds
        self.customLanguages = customLanguages
    }

    // MARK: - Patch

    /// The `PATCH /user/profile` body for what changed since `baseline`, or nil
    /// when there is nothing to send.
    ///
    /// - A name key goes out only when its value is non-empty, so an empty name is
    ///   never sent. A set name the user cleared is held (the server keeps it);
    ///   `firstNameError(from:)` / `lastNameError(from:)` flag it.
    /// - `basic` is sent when a non-empty name changed or the bio changed (an
    ///   empty bio is valid). `location` is sent when the city or State/Province
    ///   changed, or when the country is a known code that differs. A cleared
    ///   State/Province is `""`, never null (D-07).
    /// - `languages` is a full replace on the server, so it is sent only when the
    ///   ids changed, always with the custom languages, and never when it would
    ///   leave zero languages (A9).
    /// - `email` and `timezoneId` are never set.
    func patch(from baseline: ProfileSettingsSnapshot) -> UpdateUserProfileRequest? {
        var body = UpdateUserProfileRequest()

        let firstNameChanged = !firstName.isEmpty && firstName != baseline.firstName
        let lastNameChanged = !lastName.isEmpty && lastName != baseline.lastName
        if firstNameChanged || lastNameChanged || bio != baseline.bio {
            body.basic = .init(
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName,
                bio: bio
            )
        }

        let countryCode = Countries.normalize(country)
        let countryChanged = countryCode != nil && countryCode != Countries.normalize(baseline.country)
        if city != baseline.city || stateProvince != baseline.stateProvince || countryChanged {
            body.location = .init(city: city, stateProvince: stateProvince, countryCode: countryCode)
        }

        if jobTitle != baseline.jobTitle || company != baseline.company {
            body.professional = .init(jobTitle: jobTitle, company: company)
        }

        if languageIds != baseline.languageIds && !(languageIds.isEmpty && customLanguages.isEmpty) {
            body.languages = .init(languageIds: languageIds, customLanguages: customLanguages)
        }

        let isEmpty = body.basic == nil && body.location == nil
            && body.professional == nil && body.languages == nil
        return isEmpty ? nil : body
    }

    /// The snapshot after `sent` was saved: every key present in `sent` replaces
    /// the matching field, every absent key keeps this snapshot's value. A held
    /// name therefore stays at its baseline until the user types one.
    func merging(_ sent: UpdateUserProfileRequest) -> ProfileSettingsSnapshot {
        ProfileSettingsSnapshot(
            firstName: sent.basic?.firstName ?? firstName,
            lastName: sent.basic?.lastName ?? lastName,
            bio: sent.basic?.bio ?? bio,
            jobTitle: sent.professional?.jobTitle ?? jobTitle,
            company: sent.professional?.company ?? company,
            city: sent.location?.city ?? city,
            stateProvince: sent.location?.stateProvince ?? stateProvince,
            country: sent.location?.countryCode ?? country,
            languageIds: sent.languages?.languageIds ?? languageIds,
            customLanguages: sent.languages?.customLanguages ?? customLanguages
        )
    }

    // MARK: - Required names

    /// The first-name copy when the field is empty but the saved profile has one.
    func firstNameError(from baseline: ProfileSettingsSnapshot) -> String? {
        firstName.isEmpty && !baseline.firstName.isEmpty ? Self.firstNameRequired : nil
    }

    /// The last-name copy when the field is empty but the saved profile has one.
    func lastNameError(from baseline: ProfileSettingsSnapshot) -> String? {
        lastName.isEmpty && !baseline.lastName.isEmpty ? Self.lastNameRequired : nil
    }
}
