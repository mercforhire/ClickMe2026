//
//  ExpertProfileView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct PublicExpertProfile {
    let name: String
    let title: String
    let rating: Double
    let reviewCount: Int
    let yearsExp: String
    let bookings: String
    let responseTime: String
    let isOnline: Bool
    let bio: String
    let expertiseTags: [PublicExpertTag]
    let topics: [PublicTopic]
    let reviews: [PublicReview]
    let imageURL: String
}

struct PublicExpertTag {
    let label: String
    let isHighlighted: Bool
}

struct PublicTopic {
    let title: String
    let duration: String
    let description: String
    let price: String
    let isFree: Bool
}

struct PublicReview {
    let reviewer: String
    let stars: Int
    let body: String
}

// MARK: - Expert Public Profile View

struct ExpertProfileView: View {

    @StateObject private var viewModel: ExpertProfileViewModel

    var onBookSession: () -> Void
    var onMessage: () -> Void
    var onFavorite: () -> Void
    var onSeeAllReviews: () -> Void

    /// Shortcut for the expert model exposed by the view model.
    private var expert: PublicExpertProfile { viewModel.expert }

    // MARK: Init

    init(
        viewModel: ExpertProfileViewModel = ExpertProfileViewModel(),
        onBookSession: @escaping () -> Void = {},
        onMessage: @escaping () -> Void = {},
        onFavorite: @escaping () -> Void = {},
        onSeeAllReviews: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBookSession = onBookSession
        self.onMessage = onMessage
        self.onFavorite = onFavorite
        self.onSeeAllReviews = onSeeAllReviews
    }

    /// Convenience init mirroring the original signature so existing call sites
    /// that pass an expert directly keep compiling.
    init(
        expert: PublicExpertProfile,
        onBookSession: @escaping () -> Void = {},
        onMessage: @escaping () -> Void = {},
        onFavorite: @escaping () -> Void = {},
        onSeeAllReviews: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: ExpertProfileViewModel(expert: expert),
            onBookSession: onBookSession,
            onMessage: onMessage,
            onFavorite: onFavorite,
            onSeeAllReviews: onSeeAllReviews
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ExpertProfileBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ExpertProfileHero(expert: expert, glowPulse: viewModel.glowPulse)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    ExpertProfileStatsBar(
                        yearsExp: expert.yearsExp,
                        bookings: expert.bookings,
                        responseTime: expert.responseTime
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    ExpertProfileActionButtons(
                        onBookSession: onBookSession,
                        onMessage: onMessage
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    ExpertProfileAboutCard(bio: expert.bio)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    ExpertProfileExpertiseSection(tags: expert.expertiseTags)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    ExpertProfileTopicsCard(topics: expert.topics)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    ExpertProfileReviewsCard(
                        reviews: expert.reviews,
                        onSeeAllReviews: onSeeAllReviews
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
        }
        .toolbarBackground(ExpertProfileBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                    onFavorite()
                } label: {
                    Image(systemName: viewModel.isFavorited ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(viewModel.isFavorited ? ExpertProfileBrand.brandGreen : ExpertProfileBrand.onSurface)
                }
            }
        }
        .onAppear { viewModel.glowPulse = true }
    }
}

// MARK: - Sample data

extension PublicExpertProfile {
    static let sarahChen = PublicExpertProfile(
        name: "Sarah Chen",
        title: "Senior UX Architect",
        rating: 4.9,
        reviewCount: 128,
        yearsExp: "12 Yrs",
        bookings: "850+",
        responseTime: "< 2hrs",
        isOnline: true,
        bio: "Strategic UX leader with over a decade of experience building design systems for Fortune 500 tech companies. Specialized in bridging the gap between complex engineering and human-centric product design. I help designers level up their career and teams scale their design operations.",
        expertiseTags: [
            PublicExpertTag(label: "Design Systems", isHighlighted: false),
            PublicExpertTag(label: "Product Strategy", isHighlighted: false),
            PublicExpertTag(label: "Career Mentorship", isHighlighted: true),
            PublicExpertTag(label: "SaaS Architecture", isHighlighted: false),
        ],
        topics: [
            PublicTopic(title: "Intro Consultation", duration: "15 mins", description: "Discovery call", price: "Free", isFree: true),
            PublicTopic(title: "Portfolio Review", duration: "45 mins", description: "Deep dive review", price: "$120", isFree: false),
            PublicTopic(title: "System Architecture", duration: "60 mins", description: "Consultation", price: "$185", isFree: false),
        ],
        reviews: [
            PublicReview(reviewer: "Marcus R.", stars: 5,
                         body: "Sarah provided incredible insights into our design system workflow. Highly recommended!"),
            PublicReview(reviewer: "Elena V.", stars: 5,
                         body: "Very structured and helpful session. Gave me actionable steps for my senior promotion."),
        ],
        imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuBuLM2HFvVn5iq2xYO5dHjpK19mu_EIMDZPjqK9qMv_4k9iM8TChFmTqACEX1U1Y7seJaotE5worzC248lK7Bija0o6Tw1nGFJtipzoLhwviH12b31HWbNlk3JNpsQs78fDIYnmkZKldEXuJDsl9VUICiXpbHejktKaWMXUyhYQ9QP_GLQ4UCT-e7zH4a8nFpQ8zjDJvgXY56NSBf45xvhmZ-rzvdkzsAro7Nm_1dP0HWI8tm1sykwFW40ekKsX127tVbzJZTdbObM"
    )
}

// MARK: - Preview harness

private enum ExpertProfilePreviewRoute: Hashable {
    case sarahChen
    case bookmarked
}

/// Wraps the profile view inside a NavigationStack with a dummy "Search"
/// parent already pushed, so the system back chevron renders in the canvas.
private struct ExpertProfilePreviewHarness: View {
    let route: ExpertProfilePreviewRoute
    @State private var path: [ExpertProfilePreviewRoute]

    init(route: ExpertProfilePreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Search results")
                NavigationLink("View expert", value: route)
            }
            .navigationTitle("Experts")
            .navigationDestination(for: ExpertProfilePreviewRoute.self) { dest in
                switch dest {
                case .sarahChen:
                    ExpertProfileView()
                case .bookmarked:
                    ExpertProfileView(viewModel: ExpertProfileViewModel(isFavorited: true))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Sarah Chen") {
    ExpertProfilePreviewHarness(route: .sarahChen)
        .preferredColorScheme(.dark)
}

#Preview("Bookmarked") {
    ExpertProfilePreviewHarness(route: .bookmarked)
        .preferredColorScheme(.dark)
}
