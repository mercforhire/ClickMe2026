//
//  ExpertClientProfileData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `GET /expert/clients/:id`.
///
/// The expert-facing view of a client's public profile plus aggregate
/// stats about the shared expert↔client relationship. Excludes sensitive
/// fields like email and phone — experts don't need those and shouldn't
/// see them.
struct ExpertClientProfileData: Decodable {

    struct PersonalDetails: Decodable {
        let firstName: String?
        let lastName: String?
        /// Convenience concatenation from the server. Prefer this over
        /// stitching first + last locally.
        let fullName: String?
        let avatarUrl: String?
        let bio: String?
    }

    struct Location: Decodable {
        let city: String?
        let stateProvince: String?
        /// ISO-3166-1 alpha-3.
        let country: String?
        /// Human-readable timezone label, e.g. `"(GMT-08:00) Pacific Time"`.
        let timezone: String?
    }

    /// Aggregate stats about the sessions this expert has had with this
    /// client. Populated from server-side aggregation over
    /// `/expert/bookings` so the mobile client doesn't have to compute it.
    struct RelationshipStats: Decodable {
        let totalSessions: Int
        let firstSessionDate: Date?
        let lastSessionDate: Date?
    }

    let id: UUID
    let personalDetails: PersonalDetails
    let location: Location
    /// Display names of languages the client speaks (e.g. `["English", "Spanish"]`).
    let languages: [String]
    /// When this client first signed up on ClickMe.
    let memberSince: Date?
    let relationship: RelationshipStats
}
