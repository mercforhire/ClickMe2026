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
        // Server expects the multipart field named `image`, not `file`.
        try await service.multipartUpload(
            url: url(.uploadAvatar),
            parts: [.file(name: "image", filename: filename, mimeType: mimeType, data: imageData)]
        )
    }

    /// `DELETE /user/profile/avatar` — nulls out `profiles.avatar_url` and
    /// best-effort deletes the storage object. Idempotent — safe to call
    /// on an account with no avatar. Backing state (`GET /expert/profile`,
    /// `GET /user/profile`) reflects the removal on the next fetch.
    func deleteAvatar() async throws -> SuccessStatusOnlyResponse {
        try await service.httpRequest(url: url(.deleteAvatar), method: .delete)
    }

    /// `PATCH /user/password`. Session-bound password change — the caller's
    /// existing access token stays valid after a 200. Server enforces
    /// `new_password` ≥ 8 chars + at least one digit + must differ from
    /// `current_password`; validation failures come back as 422 with a
    /// `FieldValidationErrorResponse` payload. A wrong `current_password`
    /// comes back as 403 FORBIDDEN.
    func updatePassword(_ body: UpdatePasswordRequest) async throws -> SuccessMessageResponse {
        try await service.httpRequest(url: url(.updatePassword), method: .patch, body: body)
    }
}
