//
//  ExpertReviewsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertReview: Identifiable {
    let id = UUID()
    let reviewerName: String
    let reviewerImageURL: String
    let topic: String
    let stars: Double // supports half stars
    let dateLabel: String? // nil = hide date
    let body: String
}

// MARK: - Expert Reviews View

struct ExpertReviewsView: View {

    @StateObject private var viewModel: ExpertReviewsViewModel

    // MARK: Init

    init(viewModel: ExpertReviewsViewModel = ExpertReviewsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass individual content fields keep compiling.
    init(
        overallRating: Double = 4.9,
        totalReviews: Int = 128,
        reviews: [ExpertReview] = ExpertReview.samples
    ) {
        self.init(viewModel: ExpertReviewsViewModel(
            overallRating: overallRating,
            totalReviews: totalReviews,
            reviews: reviews
        ))
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ExpertReviewsBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ExpertReviewsOverallCard(
                        overallRating: viewModel.overallRating,
                        totalReviews: viewModel.totalReviews
                    )
                    .padding(.top, 8)

                    ForEach(viewModel.reviews) { review in
                        ExpertReviewsCard(review: review)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Expert Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ExpertReviewsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Sample data

extension ExpertReview {
    static let samples: [ExpertReview] = [
        ExpertReview(
            reviewerName: "Marcus Chen",
            reviewerImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            topic: "Financial Strategy",
            stars: 5,
            dateLabel: nil,
            body: "The consultation was incredibly insightful, and the advice meets modern trends to reviews and really helped clarify my strategy..."
        ),
        ExpertReview(
            reviewerName: "Elena Rodriguez",
            reviewerImageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            topic: "Marketing Audit",
            stars: 3,
            dateLabel: nil,
            body: "Solid advice on our social media strategy, and helps never commed brand customers with the right positioning..."
        ),
        ExpertReview(
            reviewerName: "Jordan Smith",
            reviewerImageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            topic: "Scaling Operations",
            stars: 5,
            dateLabel: nil,
            body: "Excellent session. The roadmap of the process to scale about an advanced and completion of tasks was invaluable..."
        ),
        ExpertReview(
            reviewerName: "Alex Rivera",
            reviewerImageURL: "https://randomuser.me/api/portraits/men/75.jpg",
            topic: "Legal Compliance",
            stars: 5,
            dateLabel: "Aug 10, 2024",
            body: "Incredibly helpful session on international regulations. Clear and actionable advice."
        ),
        ExpertReview(
            reviewerName: "Priya Patel",
            reviewerImageURL: "https://randomuser.me/api/portraits/women/68.jpg",
            topic: "UI/UX Design",
            stars: 4,
            dateLabel: "Aug 8, 2024",
            body: "Great feedback on the user flow. The new prototypes are much more intuitive."
        ),
    ]
}

// MARK: - Preview harness

private enum ExpertReviewsPreviewRoute: Hashable {
    case reviews
}

/// Wraps the expert-reviews screen inside a NavigationStack with a dummy
/// "Expert profile" parent already pushed, so the system back chevron
/// renders in the canvas.
private struct ExpertReviewsPreviewHarness: View {
    let route: ExpertReviewsPreviewRoute
    @State private var path: [ExpertReviewsPreviewRoute]

    init(route: ExpertReviewsPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("About")
                NavigationLink("All reviews", value: route)
            }
            .navigationTitle("Expert profile")
            .navigationDestination(for: ExpertReviewsPreviewRoute.self) { _ in
                ExpertReviewsView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Expert Reviews") {
    ExpertReviewsPreviewHarness(route: .reviews)
        .preferredColorScheme(.dark)
}
