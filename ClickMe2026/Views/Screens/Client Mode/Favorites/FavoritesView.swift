//
//  FavoritesView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct FavoriteExpert: Identifiable, Hashable {
    let id = UUID()
    /// Server-issued expert UUID used by `/client/favorites/:expertId`.
    /// Nil for preview/sample rows.
    let expertId: UUID?
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

    /// Expert queued for an unfavorite confirmation. Set when the user taps
    /// the heart on a card; cleared when the confirmation dialog dismisses.
    @State private var pendingUnfavorite: FavoriteExpert?

    var onExplore: () -> Void
    var onViewHistory: () -> Void

    // MARK: Init

    init(
        viewModel: FavoritesViewModel = FavoritesViewModel(),
        onExplore: @escaping () -> Void = {},
        onViewHistory: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onExplore = onExplore
        self.onViewHistory = onViewHistory
    }

    /// Convenience init that just seeds the favorites list.
    init(
        favorites: [FavoriteExpert],
        onExplore: @escaping () -> Void = {},
        onViewHistory: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: FavoritesViewModel(favorites: favorites),
            onExplore: onExplore,
            onViewHistory: onViewHistory
        )
    }

    var body: some View {
        content
            .navigationDestination(for: FavoriteExpert.self) { expert in
                ExpertProfileView(expert: PublicExpertProfile(from: expert))
            }
    }

    private var content: some View {
        ZStack {
            FavoritesBrand.bg.ignoresSafeArea()

            stateContent
                .animation(.easeInOut(duration: 0.30), value: viewModel.state)
                .animation(.easeInOut(duration: 0.30), value: viewModel.favorites.isEmpty)
        }
        .onAppear { viewModel.glowPulse = true }
        .task { await viewModel.load() }
        .confirmationDialog(
            pendingUnfavorite.map { "Remove \($0.name) from favorites?" } ?? "",
            isPresented: unfavoriteDialogBinding,
            titleVisibility: .visible,
            presenting: pendingUnfavorite
        ) { expert in
            Button("Remove", role: .destructive) {
                viewModel.removeFavorite(expert)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("You can favorite this expert again anytime from their profile.")
        }
        .alert(
            "Couldn't update favorites",
            isPresented: apiErrorBinding,
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .loaded:
            if viewModel.favorites.isEmpty {
                FavoritesEmptyState(
                    onExplore: onExplore,
                    onViewHistory: onViewHistory
                )
            } else {
                FavoritesPopulatedList(
                    favorites: viewModel.favorites,
                    onUnfavorite: { pendingUnfavorite = $0 }
                )
            }
        case .failed(let message):
            errorView(message: message)
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FavoritesBrand.brandGreen))
                .scaleEffect(1.2)
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(FavoritesBrand.onSurfaceVar)
            Text("Couldn't load favorites")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(FavoritesBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(FavoritesBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(FavoritesBrand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(FavoritesBrand.brandGreen))
            }
            .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// Binding that reflects whether an unfavorite confirmation is showing.
    /// Setting it to `false` clears the pending expert.
    private var unfavoriteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingUnfavorite != nil },
            set: { if !$0 { pendingUnfavorite = nil } }
        )
    }

    /// Binding that's `true` while `viewModel.apiError` is non-nil; clearing
    /// it dismisses the failure alert.
    private var apiErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.apiError != nil },
            set: { if !$0 { viewModel.apiError = nil } }
        )
    }
}

// MARK: - FavoriteExpert → PublicExpertProfile mapping

private extension PublicExpertProfile {
    init(from expert: FavoriteExpert) {
        // Seed only what the favorites card knows; `loadProfileDetails()`
        // on view-appear fills in rating / stats / topics from the server.
        self.init(
            expertId: expert.expertId,
            name: expert.name,
            title: expert.title,
            rating: 0,
            reviewCount: 0,
            yearsExp: "",
            bookings: "",
            isOnline: true,
            bio: expert.bio,
            expertiseTags: expert.tags.map { PublicExpertTag(label: $0, isHighlighted: false) },
            topics: [],
            reviews: [],
            imageURL: expert.imageURL
        )
    }
}

// MARK: - Sample data

extension FavoriteExpert {
    static let samples: [FavoriteExpert] = [
        FavoriteExpert(
            expertId: nil,
            name: "Sarah Chen",
            title: "Senior UX Architect",
            tags: ["Design Systems", "Strategy"],
            bio: "Helping teams scale through empathetic design systems and strategic frameworks.",
            imageURL: "https://randomuser.me/api/portraits/women/44.jpg"
        ),
        FavoriteExpert(
            expertId: nil,
            name: "Marcus Thorne",
            title: "Cloud Infrastructure",
            tags: ["AWS", "Kubernetes", "Scale"],
            bio: "Specializing in resilient cloud architecture, Kubernetes orchestration, and infrastructure optimization.",
            imageURL: "https://randomuser.me/api/portraits/men/55.jpg"
        ),
        FavoriteExpert(
            expertId: nil,
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
    NavigationStack {
        FavoritesView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    NavigationStack {
        FavoritesView(favorites: [])
    }
    .preferredColorScheme(.dark)
}
