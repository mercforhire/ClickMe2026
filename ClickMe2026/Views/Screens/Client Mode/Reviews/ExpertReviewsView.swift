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

    // MARK: Inits

    /// Runtime init — pass the expert's server UUID so the view can fetch
    /// `GET /experts/:id/reviews` on appear. Nil is acceptable but the
    /// screen will render empty content.
    init(expertId: UUID?) {
        _viewModel = StateObject(wrappedValue: ExpertReviewsViewModel(expertId: expertId))
    }

    /// Preview / test seam — inject a pre-populated view model. Skips the
    /// network path since `LoadState` is already `.loaded`.
    init(viewModel: ExpertReviewsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ExpertReviewsBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
            }
            .refreshable { await viewModel.reload() }
        }
        .navigationTitle("Expert Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ExpertReviewsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
    }

    // MARK: Content by load state

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingContent
        case .loaded:
            loadedContent
        case .failed(let message):
            errorContent(message: message)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 14) {
            ExpertReviewsOverallCard(overallRating: 5, totalReviews: 0)
                .padding(.top, 8)
                .redacted(reason: .placeholder)

            ForEach(0 ..< 3, id: \.self) { _ in
                ExpertReviewsCard(review: Self.skeletonReview)
                    .redacted(reason: .placeholder)
            }
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 14) {
            ExpertReviewsOverallCard(
                overallRating: viewModel.overallRating,
                totalReviews: viewModel.totalReviews
            )
            .padding(.top, 8)

            if viewModel.reviews.isEmpty {
                emptyView
            } else {
                ForEach(viewModel.reviews) { review in
                    ExpertReviewsCard(review: review)
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ExpertReviewsBrand.onSurfaceVar)
            Text("No reviews yet")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(ExpertReviewsBrand.onSurface)
            Text("Client reviews will appear here after their sessions.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ExpertReviewsBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ExpertReviewsBrand.onSurfaceVar)
            Text("Couldn't load reviews")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(ExpertReviewsBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ExpertReviewsBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(ExpertReviewsBrand.brandGreen))
            }
            .padding(.top, 4)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
    }

    /// Filler-only row used behind `.redacted(.placeholder)` so SwiftUI has
    /// geometry to shimmer over.
    private static let skeletonReview = ExpertReview(
        reviewerName: "\u{2003}\u{2003}\u{2003}\u{2003}",
        reviewerImageURL: "",
        topic: "\u{2003}\u{2003}\u{2003}\u{2003}",
        stars: 5,
        dateLabel: nil,
        body: "\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}"
    )
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

// MARK: - Live-fetch bootstrap

/// Bootstraps by calling `/client/home` to grab a real expertId, then
/// pushes `ExpertReviewsView` which fetches the review list via
/// `GET /experts/:id/reviews`. Custom async logic — can't be swapped for
/// the generic `PreviewNavHarness` closure.
private struct LiveFetchReviewsBootstrap: View {
    @State private var expertId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let expertId {
            ExpertReviewsView(expertId: expertId)
        } else if let errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ExpertReviewsBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ExpertReviewsBrand.bg.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
        do {
            let home = try await ClickMeAPI.shared.getClientHome()
            guard let re = home.data.recommendedExperts.first else {
                errorMessage = "No recommended experts in the home feed to preview."
                return
            }
            expertId = re.expertId
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("Expert Reviews") {
    PreviewNavHarness(parentText: "About", navTitle: "Expert profile", rowTitle: "All reviews") {
        ExpertReviewsView(
            viewModel: ExpertReviewsViewModel(
                overallRating: 4.9,
                totalReviews: 128,
                reviews: ExpertReview.samples
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "About", navTitle: "Expert profile", rowTitle: "All reviews") {
        LiveFetchReviewsBootstrap()
    }
    .preferredColorScheme(.dark)
}
