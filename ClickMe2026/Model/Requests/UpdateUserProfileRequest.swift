//
//  UpdateUserProfileRequest.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `PATCH /user/profile` (UPROF-CONSOLIDATE).
///
/// Partial-merge semantics — every group is optional; omitting a group leaves
/// that section untouched; omitting a key inside a present group leaves that
/// field untouched. An empty body (`{}`) is a valid no-op.
///
/// Notes cribbed from the OpenAPI spec:
/// - `basic.email` is accepted as a *key* but always rejected with 403.
///   Prefer to leave it `nil` — email is read-only this release.
/// - `languages`, when present, **fully replaces** `user_languages`. An empty
///   `language_ids` + `custom_languages` = intentional removal of all.
/// - Unknown `language_id` → 422 VALIDATION_ERROR.
/// - `professional` only accepts `job_title` + `company` on the server. No
///   `education` field — the profile settings screen still holds it locally
///   but has nowhere to write it right now.
struct UpdateUserProfileRequest: Encodable {

    struct Basic: Encodable {
        var firstName: String?
        var lastName: String?
        var phone: String?
        var bio: String?
        /// Included for completeness — server 403s if this is set. Leave nil.
        var email: String?
    }

    struct Location: Encodable {
        var city: String?
        var stateProvince: String?
        /// ISO 3166-1 alpha-3 (three uppercase letters, e.g. "USA").
        var countryCode: String?
        /// IANA timezone identifier.
        var timezoneId: String?
        /// Control flag; not persisted server-side.
        var autoDetectTimezone: Bool?
    }

    struct Professional: Encodable {
        var jobTitle: String?
        var company: String?
    }

    struct Languages: Encodable {
        var languageIds: [String]?
        var customLanguages: [String]?
    }

    var basic: Basic?
    var location: Location?
    var professional: Professional?
    var languages: Languages?
}
