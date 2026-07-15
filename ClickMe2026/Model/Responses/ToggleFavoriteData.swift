//
//  ToggleFavoriteData.swift
//  ClickMe2026
//

import Foundation

/// Response body for `PUT` / `DELETE /client/favorites/:expertId`. Confirms
/// the resulting favorite state so the client can reconcile if its
/// optimistic UI drifted.
struct ToggleFavoriteData: Decodable {
    let expertId: UUID
    let isFavorite: Bool
}
