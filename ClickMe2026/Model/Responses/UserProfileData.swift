//
//  UserProfileData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Shared profile for any authenticated user (client or expert).
///
/// x-discrepancy #17: `location.country` holds the alpha-3 country_code value
/// (e.g. "USA"), NOT a human-readable country name.
struct UserProfileData: Decodable {
    struct PersonalDetails: Decodable {
        let firstName: String?
        let lastName: String?
        let email: String?
        let phone: String?
        let avatarUrl: String?
        let bio: String?
    }

    struct ProfessionalDetails: Decodable {
        let jobTitle: String?
        let company: String?
        let education: String?
    }

    struct Location: Decodable {
        let city: String?
        let stateProvince: String?
        /// ⚠ x-discrepancy #17: key named `country` but holds alpha-3 code (e.g. "USA").
        let country: String?
        let timezone: String?
    }

    struct LanguageEntry: Decodable {
        let id: String?
        let label: String?
    }

    let personalDetails: PersonalDetails
    let professionalDetails: ProfessionalDetails
    let location: Location
    let languages: [LanguageEntry]
}
