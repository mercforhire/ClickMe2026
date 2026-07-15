//
//  FavoritesView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct FavoriteExpert: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let tags: [String]
    let bio: String
    let imageURL: String
    var isFavorited: Bool = true
}

// MARK: - Favorite Experts View

struct FavoritesView: View {

    @StateObject private var viewModel: FavoritesViewModel

    var onBookSession: (FavoriteExpert) -> Void
    var onExplore: () -> Void
    var onViewHistory: () -> Void

    // MARK: Init

    init(
        viewModel: FavoritesViewModel = FavoritesViewModel(),
        onBookSession: @escaping (FavoriteExpert) -> Void = { _ in },
        onExplore: @escaping () -> Void = {},
        onViewHistory: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBookSession = onBookSession
        self.onExplore = onExplore
        self.onViewHistory = onViewHistory
    }

    /// Convenience init that just seeds the favorites list.
    init(
        favorites: [FavoriteExpert],
        onBookSession: @escaping (FavoriteExpert) -> Void = { _ in },
        onExplore: @escaping () -> Void = {},
        onViewHistory: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: FavoritesViewModel(favorites: favorites),
            onBookSession: onBookSession,
            onExplore: onExplore,
            onViewHistory: onViewHistory
        )
    }

    var body: some View {
        ZStack {
            FavoritesBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.favorites.isEmpty {
                    FavoritesEmptyState(
                        onExplore: onExplore,
                        onViewHistory: onViewHistory
                    )
                } else {
                    FavoritesPopulatedList(
                        favorites: viewModel.favorites,
                        onUnfavorite: { viewModel.removeFavorite($0) },
                        onBookSession: onBookSession
                    )
                }
            }
            .animation(.easeInOut(duration: 0.30), value: viewModel.favorites.isEmpty)
        }
        .onAppear { viewModel.glowPulse = true }
    }
}

// MARK: - Sample data

extension FavoriteExpert {
    static let samples: [FavoriteExpert] = [
        FavoriteExpert(
            name: "Sarah Chen",
            title: "Senior UX Architect",
            tags: ["Design Systems", "Strategy"],
            bio: "Helping teams scale through empathetic design systems and strategic frameworks.",
            imageURL: "https://randomuser.me/api/portraits/women/44.jpg"
        ),
        FavoriteExpert(
            name: "Marcus Thorne",
            title: "Cloud Infrastructure",
            tags: ["AWS", "Kubernetes", "Scale"],
            bio: "Specializing in resilient cloud architecture, Kubernetes orchestration, and infrastructure optimization.",
            imageURL: "https://randomuser.me/api/portraits/men/55.jpg"
        ),
        FavoriteExpert(
            name: "Elena Rodriguez",
            title: "Growth Specialist",
            tags: ["Fintech", "Data Analysis"],
            bio: "Focusing on data-driven growth strategies and fintech innovation.",
            imageURL: "https://randomuser.me/api/portraits/women/68.jpg"
        ),
    ]
}

// MARK: - Previews

#Preview("With Favorites") {
    FavoritesView()
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    FavoritesView(favorites: [])
        .preferredColorScheme(.dark)
}
