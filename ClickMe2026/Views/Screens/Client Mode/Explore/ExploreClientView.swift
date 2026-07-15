//
//  ExploreClientView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertCategory: Identifiable {
    let id = UUID()
    /// Category slug from `/categories` (e.g. `"design"`, `"technology"`).
    /// Empty for local placeholder rows. Used to drive the server-side
    /// filter via `applySelectedCategories(_:)`.
    let slug: String
    let icon: String
    let name: String
    var isSelected: Bool = false
}

struct Expert: Identifiable, Hashable {
    let id = UUID()
    /// Server-issued expert UUID. Nil for hardcoded preview seeds.
    let expertId: UUID?
    let name: String
    let title: String
    let tags: [String]
    let rating: Double
    /// URL from the server (`profile_image_url` / `avatar_url`). May be empty
    /// when the server omitted the field; the card renders a gradient
    /// placeholder in that case.
    let imageURL: String
}

// MARK: - Explore navigation routes

/// Non-Expert destinations pushable from Explore. Extended as needed.
private enum ExploreRoute: Hashable {
    case favorites
}

// MARK: - Explore View

struct ExploreClientView: View {

    @StateObject private var viewModel: ExploreClientViewModel

    /// Heterogeneous nav stack — pushes `Expert` (profile detail) and
    /// `ExploreRoute` (favorites).
    @State private var path = NavigationPath()

    init(viewModel: ExploreClientViewModel = ExploreClientViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Expert.self) { expert in
                    ExpertProfileView(expert: PublicExpertProfile(from: expert))
                }
                .navigationDestination(for: ExploreRoute.self) { route in
                    switch route {
                    case .favorites:
                        FavoritesView()
                    }
                }
        }
    }

    private var content: some View {
        ZStack {
            ExploreBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ExploreHeroHeader(
                        onFavoritesTap: { path.append(ExploreRoute.favorites) }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                    categoriesSection
                        .padding(.bottom, 32)

                    expertsSection
                        .padding(.bottom, 32)
                }
            }
            .refreshable {
                await viewModel.reload()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showAllCategories) {
            AllCategoriesView(
                viewModel: CategoriesModalViewModel(selectedIds: viewModel.selectedCategorySlugs),
                onSelectionChanged: { slugs in
                    viewModel.applySelectedCategories(slugs)
                }
            )
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: Sections

    @ViewBuilder
    private var categoriesSection: some View {
        switch viewModel.categoriesState {
        case .idle, .loading:
            ExploreCategoriesSection(
                categories: Self.placeholderCategories,
                onSelect: { _ in },
                onViewAll: {}
            )
            .redacted(reason: .placeholder)

        case .loaded:
            ExploreCategoriesSection(
                categories: viewModel.categories,
                onSelect: { viewModel.selectCategory(at: $0) },
                onViewAll: { viewModel.showAllCategories = true }
            )

        case .failed(let message):
            sectionError(title: "Trending Categories", message: message)
        }
    }

    @ViewBuilder
    private var expertsSection: some View {
        switch viewModel.expertsState {
        case .idle, .loading:
            ExploreExpertsSection(
                experts: Self.placeholderExperts,
                onViewProfile: { _ in }
            )
            .redacted(reason: .placeholder)

        case .loaded:
            ExploreExpertsSection(
                experts: viewModel.experts,
                onViewProfile: { expert in path.append(expert) }
            )

        case .failed(let message):
            sectionError(title: "Featured Experts", message: message)
        }
    }

    private func sectionError(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                Text(message)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    Task { await viewModel.reload() }
                } label: {
                    Text("Retry")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(ExploreBrand.brandGreen))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: Skeleton seeds

    /// Fixed-size seed rows so `.redacted(.placeholder)` has geometry to draw.
    /// Content is irrelevant — SwiftUI hides the text/icons under the redaction.
    private static let placeholderCategories: [ExpertCategory] = (0 ..< 5).map { _ in
        ExpertCategory(slug: "", icon: "square.grid.2x2", name: "\u{2003}\u{2003}\u{2003}", isSelected: false)
    }

    private static let placeholderExperts: [Expert] = (0 ..< 2).map { _ in
        Expert(
            expertId: nil,
            name: "\u{2003}\u{2003}\u{2003}\u{2003}",
            title: "\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}",
            tags: ["\u{2003}\u{2003}", "\u{2003}\u{2003}"],
            rating: 5.0,
            imageURL: ""
        )
    }
}

// MARK: - Expert → PublicExpertProfile mapping

private extension PublicExpertProfile {
    init(from expert: Expert) {
        // Seed only what the Explore card knows; `loadProfileDetails()`
        // on view-appear fills in bio, stats, and topics from the server.
        self.init(
            expertId: expert.expertId,
            name: expert.name,
            title: expert.title,
            rating: expert.rating,
            reviewCount: 0,
            yearsExp: "",
            bookings: "",
            isOnline: true,
            bio: "",
            expertiseTags: expert.tags.map { PublicExpertTag(label: $0, isHighlighted: false) },
            topics: [],
            reviews: [],
            imageURL: expert.imageURL
        )
    }
}

// MARK: - Previews

/// Canvas-only seed data. Never used by the shipping runtime.
private enum ExplorePreviewSeed {

    static let categories: [ExpertCategory] = [
        ExpertCategory(slug: "marketing", icon: "megaphone.fill", name: "Marketing", isSelected: false),
        ExpertCategory(slug: "design", icon: "pencil.and.ruler", name: "Design", isSelected: true),
        ExpertCategory(slug: "finance", icon: "chart.line.uptrend.xyaxis", name: "Finance", isSelected: false),
        ExpertCategory(slug: "coaching", icon: "brain.head.profile", name: "Coaching", isSelected: false),
        ExpertCategory(slug: "technology", icon: "chevron.left.forwardslash.chevron.right", name: "Tech", isSelected: false)
    ]

    static let experts: [Expert] = [
        Expert(expertId: nil, name: "Elena Rodriguez", title: "Senior Brand Strategist",
               tags: ["Branding", "UX Research"], rating: 4.9, imageURL: ""),
        Expert(expertId: nil, name: "Marcus Chen", title: "Growth Hacker & Analyst",
               tags: ["SEO", "PPC"], rating: 5.0, imageURL: ""),
        Expert(expertId: nil, name: "Dr. Sarah Jenkins", title: "Venture Capital Consultant",
               tags: ["Fundraising", "Scaling"], rating: 4.8, imageURL: "")
    ]
}

#Preview("Loaded") {
    ExploreClientView(
        viewModel: ExploreClientViewModel(
            previewCategories: ExplorePreviewSeed.categories,
            previewExperts: ExplorePreviewSeed.experts
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    // Hits the real backend on appear. Token comes from the gitignored
    // `PreviewSecrets.swift`. If that file is missing or empty, the request
    // will 401 and the error view will render.
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return ExploreClientView()
        .preferredColorScheme(.dark)
}
