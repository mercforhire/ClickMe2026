//
//  SetupExpertProfileData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `PATCH /expert/profile/setup`.
///
/// The endpoint reports **completion status** rather than echoing the profile
/// back — the client just sent every field, so the interesting information is
/// what's still missing and where the user should go next. `missing_fields`
/// uses server-side field names (e.g. `"profile_image_url"`) — mostly
/// informational; the client's own checklist derives from the accumulator.
struct SetupExpertProfileData: Decodable {
    let profileId: UUID
    let completionPercentage: Int
    let missingFields: [String]
    /// Server suggestion for the next screen (e.g. `"/onboarding/photo"`).
    /// Currently only surfaced for logging — the app's navigation is driven
    /// by the local `SignupAccumulator` checklist.
    let nextRecommendedStep: String?
}
