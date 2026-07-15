//
//  MediaUploadData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `POST /user/profile/avatar` — the public URL of
/// the uploaded avatar.
///
/// NOTE: `POST /media/upload` (`uploadMedia`) is also typed to return this
/// model but hasn't been exercised end-to-end yet; if that endpoint uses
/// a different response shape (`{"url": ...}`), split into a separate
/// `AvatarUploadData` and re-shape `MediaUploadData` accordingly.
struct MediaUploadData: Decodable {
    let avatarUrl: String
}
