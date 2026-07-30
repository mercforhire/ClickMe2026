//
//  UpdateExpertProfileData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// `PATCH /expert/profile` — thin confirmation payload the server returns
/// after a partial update. Does NOT carry the full profile snapshot; if
/// callers need the fresh state they should follow up with
/// `GET /expert/profile` (via `UserManager.refreshExpertProfile()`).
struct UpdateExpertProfileData: Decodable {
    let profileId: UUID
    /// Server-side echo of the fields that actually changed, snake-case
    /// keys (e.g. `"expertise_tags"`, `"personal_info"`).
    let updatedFields: [String]
}
