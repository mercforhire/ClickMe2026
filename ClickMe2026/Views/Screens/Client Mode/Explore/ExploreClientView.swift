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
    let icon: String
    let name: String
    var isSelected: Bool = false
}

struct Expert: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let title: String
    let tags: [String]
    let rating: Double
    /// URL from the server (`profile_image_url` / `avatar_url`). May be empty
    /// when the server omitted the field; the card renders a gradient
    /// placeholder in that case.
    let imageURL: String
}

// MARK: - Explore View

struct ExploreClientView: View {

    @StateObject private var viewModel: ExploreClientViewModel
    @State private var path: [Expert] = []

    init(viewModel: ExploreClientViewModel = ExploreClientViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Expert.self) { expert in
                    ExpertProfileView(expert: PublicExpertProfile(from: expert))
                }
        }
    }

    private var content: some View {
        ZStack {
            ExploreBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ExploreHeroHeader()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    ExploreSearchBar(text: $viewModel.searchText)
                        .padding(.horizontal, 20)
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
            AllCategoriesView { selectedCategory in
                viewModel.selectCategory(named: selectedCategory.name)
            }
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
        ExpertCategory(icon: "square.grid.2x2", name: "\u{2003}\u{2003}\u{2003}", isSelected: false)
    }

    private static let placeholderExperts: [Expert] = (0 ..< 2).map { _ in
        Expert(
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
        self.init(
            name: expert.name,
            title: expert.title,
            rating: expert.rating,
            reviewCount: PublicExpertProfile.sarahChen.reviewCount,
            yearsExp: PublicExpertProfile.sarahChen.yearsExp,
            bookings: PublicExpertProfile.sarahChen.bookings,
            responseTime: PublicExpertProfile.sarahChen.responseTime,
            isOnline: true,
            bio: PublicExpertProfile.sarahChen.bio,
            expertiseTags: expert.tags.map { PublicExpertTag(label: $0, isHighlighted: false) },
            topics: PublicExpertProfile.sarahChen.topics,
            reviews: PublicExpertProfile.sarahChen.reviews,
            imageURL: PublicExpertProfile.sarahChen.imageURL
        )
    }
}

// MARK: - Previews

/// Canvas-only seed data. Never used by the shipping runtime.
private enum ExplorePreviewSeed {

    static let categories: [ExpertCategory] = [
        ExpertCategory(icon: "megaphone.fill", name: "Marketing", isSelected: false),
        ExpertCategory(icon: "pencil.and.ruler", name: "Design", isSelected: true),
        ExpertCategory(icon: "chart.line.uptrend.xyaxis", name: "Finance", isSelected: false),
        ExpertCategory(icon: "brain.head.profile", name: "Coaching", isSelected: false),
        ExpertCategory(icon: "chevron.left.forwardslash.chevron.right", name: "Tech", isSelected: false)
    ]

    static let experts: [Expert] = [
        Expert(name: "Elena Rodriguez", title: "Senior Brand Strategist",
               tags: ["Branding", "UX Research"], rating: 4.9, imageURL: ""),
        Expert(name: "Marcus Chen", title: "Growth Hacker & Analyst",
               tags: ["SEO", "PPC"], rating: 5.0, imageURL: ""),
        Expert(name: "Dr. Sarah Jenkins", title: "Venture Capital Consultant",
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
    // Uses the default init — hits the real backend on appear. Requires a
    // valid client-role bearer token in the shared keychain.
    ExploreClientView()
        .preferredColorScheme(.dark)
}
