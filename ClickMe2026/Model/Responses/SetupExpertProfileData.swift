//
//  SetupExpertProfileData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `PATCH /expert/profile/setup`.
///
/// `missingFields` uses server-side field names (e.g. `"hourly_rate"`) —
/// mostly informational for logging. `setupCompleted` is authoritative
/// and drives the app's resume/dashboard routing decisions.
struct SetupExpertProfileData: Decodable {
    let profileId: UUID
    let completionPercentage: Int
    let missingFields: [String]
    /// Server suggestion for the next screen (e.g. `"/onboarding/photo"`).
    let nextRecommendedStep: String?
    /// `true` once the client has sent `setup_completed: true` and every
    /// required field is populated. Used by splash/login gates.
    let setupCompleted: Bool
}
