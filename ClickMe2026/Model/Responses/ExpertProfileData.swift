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

    let profileId: UUID
    let avatarUrl: String?
    let personalInfo: PersonalInfo
    let professionalDetails: ProfessionalDetails
    let locationDetails: LocationDetails
    let languages: [LanguageEntry]
}
