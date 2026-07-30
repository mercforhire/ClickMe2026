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

/// Featured topic tile shown in the horizontal "Featured Topics" strip.
/// Populated from `/client/home` → `featured_topics`. `priceLabel` is a
/// pre-formatted display string (e.g. `"$120"`) so the card can render
/// without doing currency math.
struct FeaturedTopic: Identifiable, Hashable {
    let id = UUID()
    /// Server topic id.
    let topicId: UUID
    let title: String
    /// Pre-formatted, e.g. `"$120"` or `"Free"`.
    let priceLabel: String
    let expertId: UUID
    let expertName: String
    /// May be empty when the server omitted the URL.
    let expertImageURL: String
}

// MARK: - Explore View

struct ExploreClientView: View {

    @StateObject private var viewModel: ExploreClientViewModel

    /// Push path is provided by the enclosing `HomeClientView` via
    /// `@Environment(\.homeNavigationPath)`. When rendered outside the
    /// shell (previews, tests) the fallback `_localPath` provides a
    /// self-contained NavigationStack so the screen still works.
    @Environment(\.homeNavigationPath) private var navPath
    @State private var _localPath = NavigationPath()

    /// Fired when the user taps "See all" next to Recommended Experts.
    /// Wired by the shell to switch to the Search tab, which is the
    /// natural "browse everyone" surface. Defaults to a no-op so
    /// previews without a shell still compile.
    var onSeeAllExperts: () -> Void = {}

    /// Bound to `CallCenter.shared.joinError` so a failed join surfaces
    /// an alert on this screen without keeping any modal on screen.
    /// Actual call presentation lives on the shell's `CallOverlayHost`.
    @ObservedObject private var callCenter = CallCenter.shared

    init(
        viewModel: ExploreClientViewModel = ExploreClientViewModel(),
        onSeeAllExperts: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSeeAllExperts = onSeeAllExperts
    }

    var body: some View {
        // Only wrap in a NavigationStack when there's no ambient one.
        Group {
            if navPath != nil {
                contentWithDestinations
            } else {
                NavigationStack(path: $_localPath) {
                    contentWithDestinations
                }
            }
        }
    }

    /// Push a route onto whichever nav stack is active — the shell's
    /// shared path if we're hosted, else the local fallback path.
    private func push<V: Hashable>(_ value: V) {
        if let navPath {
            navPath.push(value)
        } else {
            _localPath.append(value)
        }
    }

    private var contentWithDestinations: some View {
        content
            .navigationDestination(for: Expert.self) { expert in
                ExpertProfileView(expert: PublicExpertProfile(from: expert))
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
                        .padding(.bottom, 28)

                    todaysSessionsSection

                    categoriesSection
                        .padding(.bottom, 32)

                    featuredTopicsSection

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
        // Call surface is hosted globally by `CallOverlayHost` on the
        // shell. This screen just surfaces the join-failure alert.
        .alert(
            "Couldn't join call",
            isPresented: Binding(
                get: { callCenter.joinError != nil },
                set: { if !$0 { callCenter.joinError = nil } }
            ),
            presenting: callCenter.joinError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: Sections

    /// Client-side counterpart to the expert dashboard's Today's Sessions
    /// strip. Hidden entirely when the fetch resolves with no joinable
    /// bookings for today — the section adds no scaffolding until there's
    /// something worth showing.
    @ViewBuilder
    private var todaysSessionsSection: some View {
        if !viewModel.todaysSessions.isEmpty {
            ExploreTodaysSessionsSection(
                sessions: viewModel.todaysSessions,
                onJoinCall: { booking in
                    CallCenter.shared.startCall(
                        bookingId: booking.id,
                        peerId: booking.expertId,
                        peerName: booking.expertName,
                        peerImageURL: booking.imageURL,
                        topic: booking.topic,
                        scheduledStart: booking.startTime,
                        scheduledEnd: booking.endTime
                    )
                },
                onTapCard: { _ in }
            )
            .padding(.bottom, 32)
        }
    }

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

    /// Hidden entirely when the strip has no topics — either because the
    /// backend hasn't deployed the field yet, the account has no
    /// eligible topics, or the load failed. This keeps the screen valid
    /// against pre-deploy servers without leaving an empty header on
    /// screen.
    @ViewBuilder
    private var featuredTopicsSection: some View {
        if !viewModel.featuredTopics.isEmpty {
            ExploreFeaturedTopicsSection(
                topics: viewModel.featuredTopics,
                onSeeAll: onSeeAllExperts,
                onTapTopic: { topic in
                    push(Expert(
                        expertId: topic.expertId,
                        name: topic.expertName,
                        title: "",
                        tags: [],
                        rating: 0,
                        imageURL: topic.expertImageURL
                    ))
                }
            )
            .padding(.bottom, 32)
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
                onSeeAll: onSeeAllExperts,
                onViewProfile: { expert in push(expert) }
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

    static let featuredTopics: [FeaturedTopic] = [
        FeaturedTopic(topicId: UUID(), title: "Scaling Design Systems",
                      priceLabel: "$120", expertId: UUID(),
                      expertName: "Elena Rodriguez", expertImageURL: ""),
        FeaturedTopic(topicId: UUID(), title: "Crypto Investment Strategy",
                      priceLabel: "$250", expertId: UUID(),
                      expertName: "Marcus Chen", expertImageURL: ""),
        FeaturedTopic(topicId: UUID(), title: "SaaS Product Marketing",
                      priceLabel: "$180", expertId: UUID(),
                      expertName: "Dr. Sarah Jenkins", expertImageURL: "")
    ]
}

#Preview("Loaded") {
    ExploreClientView(
        viewModel: ExploreClientViewModel(
            previewCategories: ExplorePreviewSeed.categories,
            previewExperts: ExplorePreviewSeed.experts,
            previewFeaturedTopics: ExplorePreviewSeed.featuredTopics
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
