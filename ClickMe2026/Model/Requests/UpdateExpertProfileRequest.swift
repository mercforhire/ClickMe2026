//
//  UpdateExpertProfileRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `PATCH /expert/profile` — partial update of expert profile.
struct UpdateExpertProfileRequest: Encodable {
    struct PersonalInfo: Encodable {
        let firstName: String?
        let lastName: String?
        let phone: String?
        let bio: String?
    }

    struct ProfessionalDetails: Encodable {
        let jobTitle: String?
        let company: String?
        let education: String?
        let meetingUrl: String?
    }

    struct LocationDetails: Encodable {
        let city: String?
        let stateProvince: String?
        let countryCode: String?
        let timezone: String?
    }

    struct ExpertiseTag: Encodable {
        let tagId: String
        let isPrimary: Bool
    }

    let personalInfo: PersonalInfo?
    let professionalDetails: ProfessionalDetails?
    let locationDetails: LocationDetails?
    let languages: [String]?
    let expertiseTags: [ExpertiseTag]?
}
