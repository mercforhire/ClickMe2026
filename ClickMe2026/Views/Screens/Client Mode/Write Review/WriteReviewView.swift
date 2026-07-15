//
//  WriteReviewView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Leave Review View

struct WriteReviewView: View {

    @StateObject private var viewModel: WriteReviewViewModel

    /// Fired after the server acknowledges a successful post. Parents (e.g.
    /// `MyBookingsView`) typically use this to dismiss + refresh.
    var onSubmit: (Int, String) -> Void

    // MARK: Inits

    /// Runtime init. Requires the server booking UUID + its status — reviews
    /// are only accepted for `.completed` bookings and the screen enforces
    /// that gate before showing the form.
    init(
        bookingId: UUID,
        bookingStatus: PastBookingStatus,
        seedExpertName: String = "",
        seedExpertImageURL: String = "",
        onSubmit: @escaping (Int, String) -> Void = { _, _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: WriteReviewViewModel(
                bookingId: bookingId,
                bookingStatus: bookingStatus,
                seedExpertName: seedExpertName,
                seedExpertImageURL: seedExpertImageURL
            )
        )
        self.onSubmit = onSubmit
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: WriteReviewViewModel,
        onSubmit: @escaping (Int, String) -> Void = { _, _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSubmit = onSubmit
    }

    // MARK: Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WriteReviewBrand.topTint, WriteReviewBrand.bg],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.55)
            )
            .ignoresSafeArea()

            content
        }
        .onAppear {
            viewModel.glowPulse = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.25)) {
                viewModel.starsAnimated = true
            }
        }
        .task { await viewModel.onAppear() }
        .alert(
            "Couldn't submit review",
            isPresented: presenting(\.submitError),
            presenting: viewModel.submitError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: Content router

    @ViewBuilder
    private var content: some View {
        if !viewModel.isEligible {
            ineligibleContent
        } else {
            switch viewModel.contextState {
            case .idle, .loading:
                loadingContent
            case .failed(let message):
                errorContent(message: message)
            case .loaded:
                formContent
            }
        }
    }

    // MARK: Form

    private var formContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    WriteReviewExpertAvatar(
                        imageURL: viewModel.expertImageURL,
                        glowPulse: viewModel.glowPulse
                    )
                    .padding(.bottom, 28)

                    WriteReviewHeadline(expertName: viewModel.expertName)
                        .padding(.horizontal, 28)
                        .padding(.bottom, viewModel.sessionTopic == nil ? 32 : 8)

                    if let topic = viewModel.sessionTopic {
                        Text(topic)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(WriteReviewBrand.onSurfaceVar)
                            .padding(.bottom, 24)
                    }

                    if viewModel.hasSubmittedBefore && !viewModel.didSubmit {
                        alreadySubmittedBanner
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }

                    WriteReviewStarRating(
                        selectedStars: viewModel.selectedStars,
                        hoverStar: viewModel.hoverStar,
                        starsAnimated: viewModel.starsAnimated,
                        onSelect: { viewModel.selectStar($0) }
                    )
                    .padding(.bottom, 28)

                    WriteReviewTextField(text: $viewModel.reviewText)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }

            WriteReviewSubmitButton(
                isSubmitting: viewModel.isSubmitting,
                didSubmit: viewModel.didSubmit,
                action: { viewModel.submit(onSuccess: onSubmit) }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
    }

    private var alreadySubmittedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(WriteReviewBrand.brandGreen)
            Text("You've reviewed this session before. Submitting again will update your existing review.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurfaceVar)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: Ineligible / loading / error states

    private var ineligibleContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(WriteReviewBrand.onSurfaceVar.opacity(0.6))
            Text("Review not available")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurface)
            Text(ineligibleMessage)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ineligibleMessage: String {
        switch viewModel.bookingStatus {
        case .completed:
            return "" // never reached
        case .cancelled:
            return "This session was cancelled, so a review isn't available."
        case .missed:
            return "This session was missed, so a review isn't available."
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(WriteReviewBrand.onSurface)
            Text("Loading review…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(WriteReviewBrand.onSurfaceVar)
            Text("Couldn't load review")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.onAppear() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(WriteReviewBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Binding helper

    /// Binding that's `true` while `keyPath` is non-nil; setting it to
    /// `false` clears the underlying value.
    private func presenting(_ keyPath: ReferenceWritableKeyPath<WriteReviewViewModel, String?>) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { if !$0 { viewModel[keyPath: keyPath] = nil } }
        )
    }
}

// MARK: - Preview harness

private enum WriteReviewPreviewRoute: Hashable {
    case fiveStar
    case alreadySubmitted
    case submitted
    case ineligibleMissed
}

/// Wraps the write-review screen inside a NavigationStack with a dummy
/// "My Bookings" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct WriteReviewPreviewHarness: View {
    let route: WriteReviewPreviewRoute
    @State private var path: [WriteReviewPreviewRoute]

    init(route: WriteReviewPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Past sessions")
                NavigationLink("Leave a review", value: route)
            }
            .navigationTitle("My Bookings")
            .navigationDestination(for: WriteReviewPreviewRoute.self) { dest in
                switch dest {
                case .fiveStar:
                    WriteReviewView(viewModel: .previewSeed())
                case .alreadySubmitted:
                    WriteReviewView(viewModel: .previewSeed(
                        selectedStars: 4,
                        reviewText: "Helpful discussion — appreciated the concrete next steps.",
                        hasSubmittedBefore: true,
                        starsAnimated: true
                    ))
                case .submitted:
                    WriteReviewView(viewModel: .previewSeed(
                        selectedStars: 5,
                        reviewText: "Outstanding consultation — I left with a clear action plan.",
                        didSubmit: true,
                        starsAnimated: true
                    ))
                case .ineligibleMissed:
                    WriteReviewView(viewModel: .previewSeed(
                        bookingStatus: .missed,
                        expertName: "Marcus Chen"
                    ))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Default — 5 stars") {
    WriteReviewPreviewHarness(route: .fiveStar)
        .preferredColorScheme(.dark)
}

#Preview("Already submitted") {
    WriteReviewPreviewHarness(route: .alreadySubmitted)
        .preferredColorScheme(.dark)
}

#Preview("Submitted state") {
    WriteReviewPreviewHarness(route: .submitted)
        .preferredColorScheme(.dark)
}

#Preview("Ineligible (missed)") {
    WriteReviewPreviewHarness(route: .ineligibleMissed)
        .preferredColorScheme(.dark)
}
