//
//  ClickMeAPI+UserProfile.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getUserProfile() async throws -> SuccessDataResponse<UserProfileData> {
        try await service.httpRequest(url: url(.getUserProfile), method: .get)
    }

    /// Consolidated partial-merge profile update (`PATCH /user/profile`).
    /// See `UpdateUserProfileRequest` for body semantics. Response mirrors
    /// `GET /user/profile` — callers should re-hydrate view state from it.
    func updateUserProfile(_ body: UpdateUserProfileRequest) async throws -> SuccessDataResponse<UserProfileData> {
        try await service.httpRequest(url: url(.updateUserProfile), method: .patch, body: body)
    }

    func uploadAvatar(imageData: Data, filename: String = "avatar.jpg", mimeType: String = "image/jpeg") async throws -> SuccessDataResponse<MediaUploadData> {
        try await service.multipartUpload(
            url: url(.uploadAvatar),
            parts: [.file(name: "file", filename: filename, mimeType: mimeType, data: imageData)]
        )
    }
}
