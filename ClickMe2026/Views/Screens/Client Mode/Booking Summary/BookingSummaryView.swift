//
//  BookingSummaryView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Session Summary View

struct BookingSummaryView: View {

    @StateObject private var viewModel: BookingSummaryViewModel

    /// Fires with the resolved expert seed when the user taps "Book Again".
    /// `nil` is passed if the seed isn't ready yet (fetch pending or missing
    /// `expert.id`) — callers typically no-op in that case.
    var onBookAgain: (BookAgainSeed?) -> Void
    var onMessageExpert: () -> Void
    var onLeaveReview: () -> Void

    // MARK: Init

    /// Runtime init — hydrates the screen from `GET /client/bookings/:id`
    /// and `GET /bookings/:id/reviews/context`.
    init(
        bookingId: UUID,
        onBookAgain: @escaping (BookAgainSeed?) -> Void = { _ in },
        onMessageExpert: @escaping () -> Void = {},
        onLeaveReview: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: BookingSummaryViewModel(bookingId: bookingId))
        self.onBookAgain = onBookAgain
        self.onMessageExpert = onMessageExpert
        self.onLeaveReview = onLeaveReview
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: BookingSummaryViewModel,
        onBookAgain: @escaping (BookAgainSeed?) -> Void = { _ in },
        onMessageExpert: @escaping () -> Void = {},
        onLeaveReview: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBookAgain = onBookAgain
        self.onMessageExpert = onMessageExpert
        self.onLeaveReview = onLeaveReview
    }

    /// Resolved seed for the current session — passed to `onBookAgain` when
    /// the button fires. Nil until the booking detail fetch settles.
    private var bookAgainSeed: BookAgainSeed? {
        guard let expertId = viewModel.expertId else { return nil }
        return BookAgainSeed(
            expertId: expertId,
            expertName: viewModel.expertName,
            expertTitle: viewModel.expertTitle,
            expertImageURL: viewModel.expertImageURL
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            BookingSummaryBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Session Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BookingSummaryBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                BookingSummaryExpertCard(
                    expertName: viewModel.expertName,
                    expertTitle: viewModel.expertTitle,
                    expertImageURL: viewModel.expertImageURL,
                    topic: viewModel.topic,
                    dateTime: viewModel.dateTime,
                    pricePaid: viewModel.pricePaid
                )

                if viewModel.hasSubmittedReview {
                    BookingSummaryFeedback(
                        feedbackStars: viewModel.feedbackStars,
                        feedbackText: viewModel.feedbackText
                    )
                }

                BookingSummaryActions(
                    onBookAgain: { onBookAgain(bookAgainSeed) },
                    onMessageExpert: onMessageExpert
                )
                .padding(.top, 16)

                if !viewModel.hasSubmittedReview {
                    leaveReviewButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(BookingSummaryBrand.onSurface)
            Text("Loading session…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
            Text("Couldn't load session")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(BookingSummaryBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
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
                    .background(Capsule().fill(BookingSummaryBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// CTA surfaced when the user hasn't left a review yet. Delegates to the
    /// caller via `onLeaveReview` so the parent NavigationStack can push the
    /// existing `WriteReviewView` flow.
    private var leaveReviewButton: some View {
        Button(action: onLeaveReview) {
            HStack(spacing: 8) {
                Image(systemName: "star")
                    .font(.system(size: 15, weight: .semibold))
                Text("Leave a Review")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(BookingSummaryBrand.brandGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BookingSummaryBrand.brandGreen.opacity(0.55), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

// MARK: - Live-fetch bootstrap

/// Bootstraps by hitting `GET /client/bookings?type=past` (falling back to
/// upcoming) to pick a real bookingId, then hands off to `BookingSummaryView`.
private struct LiveFetchBookingSummaryBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            BookingSummaryView(bookingId: bookingId)
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
            .background(BookingSummaryBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BookingSummaryBrand.bg.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
        do {
            let past = try await ClickMeAPI.shared.getClientBookings(type: .past)
            if let latest = past.data.bookings.sorted(by: { $0.startTime > $1.startTime }).first {
                bookingId = latest.bookingId
                return
            }
            let upcoming = try await ClickMeAPI.shared.getClientBookings(type: .upcoming)
            if let soonest = upcoming.data.bookings.sorted(by: { $0.startTime < $1.startTime }).first {
                bookingId = soonest.bookingId
                return
            }
            errorMessage = "No bookings found for this account."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("Session Summary — 5 Stars") {
    PreviewNavHarness(parentText: "Past sessions", navTitle: "My Bookings", rowTitle: "Session summary") {
        BookingSummaryView(viewModel: BookingSummaryViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Session Summary — No Review Yet") {
    PreviewNavHarness(parentText: "Past sessions", navTitle: "My Bookings", rowTitle: "Session summary") {
        BookingSummaryView(viewModel: BookingSummaryViewModel(
            feedbackStars: 0,
            feedbackText: nil,
            hasSubmittedReview: false
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "Past sessions", navTitle: "My Bookings", rowTitle: "Session summary") {
        LiveFetchBookingSummaryBootstrap()
    }
    .preferredColorScheme(.dark)
}
