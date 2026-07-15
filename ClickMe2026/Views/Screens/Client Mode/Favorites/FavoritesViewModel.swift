//
//  FavoritesViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-25.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class FavoritesViewModel: ObservableObject {


    // MARK: View state
    @Published var favorites: [FavoriteExpert]
    @Published var glowPulse: Bool
    @Published var state: LoadState = .idle

    /// Surfaced as an alert when a `DELETE /client/favorites/:id` fails and
    /// the visual state rolls back.
    @Published var apiError: String?

    // MARK: Dependencies
    private let api: ClickMeAPI

    // MARK: Inits

    /// Runtime init — starts empty; call `load()` on view appear to populate
    /// from the server.
    init(api: ClickMeAPI = .shared) {
        self.api = api
        self.favorites = []
        self.glowPulse = false
    }

    /// Preview / test seam — installs canned favorites as if a load had
    /// already succeeded.
    init(
        favorites: [FavoriteExpert],
        glowPulse: Bool = false
    ) {
        self.api = .shared
        self.favorites = favorites
        self.glowPulse = glowPulse
        self.state = .loaded
    }

    // MARK: - Load

    /// Fetches `GET /client/favorites` and populates the list. Skips
    /// re-fetching when already `.loaded`.
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    /// Pull-to-refresh handler.
    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        state = .loading
        do {
            let response = try await api.getClientFavorites()
            favorites = response.data.experts.map(Self.map)
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    // MARK: - Actions

    /// Removes the favorite optimistically (drops from the list with a
    /// spring animation) and calls `DELETE /client/favorites/:id`. Rolls
    /// the row back on failure.
    func removeFavorite(_ expert: FavoriteExpert) {
        guard let expertId = expert.expertId else {
            // Preview / sample rows with no server id — behave locally only.
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                favorites.removeAll { $0.id == expert.id }
            }
            return
        }

        let previousIndex = favorites.firstIndex { $0.id == expert.id }
        let previousExpert = expert

        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            favorites.removeAll { $0.id == expert.id }
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.api.removeFavorite(expertId: expertId)
            } catch {
                // Roll the row back into the position it came from.
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    if let idx = previousIndex, idx <= self.favorites.count {
                        self.favorites.insert(previousExpert, at: idx)
                    } else {
                        self.favorites.append(previousExpert)
                    }
                }
                self.apiError = Self.message(for: error)
            }
        }
    }

    // MARK: - Mapping helpers

    private static func map(_ item: FavoriteExpertItem) -> FavoriteExpert {
        FavoriteExpert(
            expertId: item.expertId,
            name: item.fullName ?? "Expert",
            title: item.headline ?? "",
            tags: item.expertiseTags ?? [],
            // `/client/favorites` doesn't return a bio field per row; we
            // leave the card's bio empty. Card already renders empty bios
            // as an omitted line.
            bio: "",
            imageURL: item.avatarUrl ?? "",
            isFavorited: item.isFavorite
        )
    }

    // MARK: - Error helpers

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
