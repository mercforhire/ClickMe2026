//
//  ExpertProfileData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Expert's own profile, aggregated from profiles + expert_profiles + user_languages.
///
/// x-discrepancy #11: `account_settings_link` and `country_name` from the API
/// reference spec are NOT returned. `location_details.country_code` holds the
/// alpha-3 country code only.
///
/// x-discrepancy #21: `location_details` uses key `state_province` on the
/// GET response, but the PATCH input uses `province_state`. Historical
/// naming drift — the client maps both.
struct ExpertProfileData: Decodable {
    struct PersonalInfo: Decodable {
        let firstName: String?
        let lastName: String?
        let email: String?
        let phone: String?
        let bio: String?
    }

    struct ProfessionalDetails: Decodable {
        let jobTitle: String?
        let company: String?
        let education: String?
        let meetingUrl: String?
    }

    struct LocationDetails: Decodable {
        let city: String?
        let stateProvince: String?
        /// Alpha-3 country code (e.g. "USA"). `country_name` is NOT returned.
        let countryCode: String?
        let timezone: String?
    }

    struct LanguageEntry: Decodable {
        let id: String?
        let label: String?
    }

    /// Nested tag record on the GET response — post-hotfix 260724-vyy
    /// the server always emits both `is_primary` and `category_id` via
    /// the shared `readProfileExpertiseTags` helper. `category_id` is
    /// left optional to defend against a catalog tag with a null
    /// category — server confirmed the field key is always present but
    /// the value can be null in edge cases.
    struct ExpertiseTagEntry: Decodable {
        let id: UUID
        let label: String
        /// Whether this tag is the caller's primary. Server always emits
        /// a boolean (`!!row.is_primary`).
        let isPrimary: Bool
        /// Catalog category slug. Nil defensively — the key is always
        /// present but the value depends on the tag-catalog row.
        let categoryId: String?
    }

    let profileId: UUID
    let avatarUrl: String?
    let personalInfo: PersonalInfo
    let professionalDetails: ProfessionalDetails
    let locationDetails: LocationDetails
    let languages: [LanguageEntry]

    /// Empty when the expert hasn't picked any tags yet. First `is_primary=true`
    /// entry is the primary; others are secondary.
    let expertiseTags: [ExpertiseTagEntry]
    /// True after the client has sent `setup_completed: true` on the final
    /// publish and the server accepted (all required fields present).
    /// Splash + login gates read this to decide dashboard vs signup flow.
    let setupCompleted: Bool
}
