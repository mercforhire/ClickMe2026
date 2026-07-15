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
    @State private var favorites: [FavoriteExpert]
    @State private var glowPulse = false

    var onBookSession: (FavoriteExpert) -> Void
    var onMenuTap: () -> Void
    var onAvatarTap: () -> Void
    var onExplore: () -> Void
    var onViewHistory: () -> Void

    private let myAvatarURL = "https://randomuser.me/api/portraits/men/32.jpg"

    // MARK: Init

    init(
        favorites: [FavoriteExpert] = FavoriteExpert.samples,
        onBookSession: @escaping (FavoriteExpert) -> Void = { _ in },
        onMenuTap: @escaping () -> Void = {},
        onAvatarTap: @escaping () -> Void = {},
        onExplore: @escaping () -> Void = {},
        onViewHistory: @escaping () -> Void = {}
    ) {
        _favorites = State(initialValue: favorites)
        self.onBookSession = onBookSession
        self.onMenuTap = onMenuTap
        self.onAvatarTap = onAvatarTap
        self.onExplore = onExplore
        self.onViewHistory = onViewHistory
    }

    var body: some View {
        ZStack {
            FavoritesBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                FavoritesTopBar(
                    avatarURL: myAvatarURL,
                    onMenuTap: onMenuTap,
                    onAvatarTap: onAvatarTap
                )

                if favorites.isEmpty {
                    FavoritesEmptyState(
                        onExplore: onExplore,
                        onViewHistory: onViewHistory
                    )
                } else {
                    FavoritesPopulatedList(
                        favorites: favorites,
                        onUnfavorite: { expert in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                favorites.removeAll { $0.id == expert.id }
                            }
                        },
                        onBookSession: onBookSession
                    )
                }
            }
            .animation(.easeInOut(duration: 0.30), value: favorites.isEmpty)
        }
        .onAppear { glowPulse = true }
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
