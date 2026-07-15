//
//  ClickMeAPI+Favorites.swift
//  ClickMe2026
//
//  Client-role favorites endpoints. `PUT` / `DELETE` are idempotent — calling
//  them on the same expert twice is a no-op. Read-side `is_favorite` flags
//  on `/client/home`, `/experts/search`, and `/discovery/feed` reflect the
//  same underlying state.
//

import Foundation

extension ClickMeAPI {

    /// Paginated list of the signed-in client's favorited experts, newest
    /// favorited first. Server clamps `limit` to 1–100.
    func getClientFavorites(
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SuccessDataResponse<FavoritesPayload> {
        try await service.httpRequest(
            url: url(.getClientFavorites),
            method: .get,
            parameters: ["page": page, "limit": limit]
        )
    }

    /// Adds an expert to the current client's favorites. Idempotent on
    /// already-favorited experts.
    @discardableResult
    func addFavorite(expertId: UUID) async throws -> SuccessDataResponse<ToggleFavoriteData> {
        try await service.httpRequest(
            url: url(.addFavorite, id: expertId),
            method: .put
        )
    }

    /// Removes an expert from favorites. Idempotent on non-favorites.
    @discardableResult
    func removeFavorite(expertId: UUID) async throws -> SuccessDataResponse<ToggleFavoriteData> {
        try await service.httpRequest(
            url: url(.removeFavorite, id: expertId),
            method: .delete
        )
    }
}
