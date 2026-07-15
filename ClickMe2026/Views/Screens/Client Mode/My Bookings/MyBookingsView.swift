//
//  MyBookingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Navigation routes

private enum BookingRoute: Hashable {
    case upcoming(UpcomingBooking)
    case past(PastBooking)
    /// Pushed from the "Leave a Review" CTA inside `BookingSummaryView`.
    /// Carries the booking status because `WriteReviewView` gates the form
    /// on `.completed`.
    case writeReview(PastBooking)
    /// Pushed from the "Book Again" CTA inside `BookingSummaryView` — lands
    /// on `MakeABookingView` for the same expert with topics + slots ready
    /// to pick.
    case makeBooking(BookAgainSeed)
    /// Pushed from the "Cancel" action inside `UpcomingBookingView`. Loads
    /// the booking's display fields on appear and calls
    /// `POST /client/bookings/:id/cancel` on confirm.
    case cancelBooking(UpcomingBooking)
    /// Pushed from the "Reschedule" action inside `UpcomingBookingView`.
    /// Loads booking detail + expert availability and calls
    /// `PATCH /client/bookings/:id/reschedule` on confirm.
    case rescheduleBooking(UpcomingBooking)
}

// MARK: - My Bookings View

struct MyBookingsView: View {

    @StateObject private var viewModel: MyBookingsViewModel
    @State private var path: [BookingRoute] = []

    // MARK: Callbacks

    var onJoinCall: (UpcomingBooking) -> Void
    var onReschedule: (UpcomingBooking) -> Void
    var onMessage: (UpcomingBooking) -> Void
    var onPrivateNote: (PastBooking) -> Void
    var onLeaveReview: (PastBooking) -> Void
    var onExploreExperts: () -> Void

    // MARK: Init

    init(
        viewModel: MyBookingsViewModel = MyBookingsViewModel(),
        onJoinCall: @escaping (UpcomingBooking) -> Void = { _ in },
        onReschedule: @escaping (UpcomingBooking) -> Void = { _ in },
        onMessage: @escaping (UpcomingBooking) -> Void = { _ in },
        onPrivateNote: @escaping (PastBooking) -> Void = { _ in },
        onLeaveReview: @escaping (PastBooking) -> Void = { _ in },
        onExploreExperts: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onJoinCall = onJoinCall
        self.onReschedule = onReschedule
        self.onMessage = onMessage
        self.onPrivateNote = onPrivateNote
        self.onLeaveReview = onLeaveReview
        self.onExploreExperts = onExploreExperts
    }

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            screen
                .navigationDestination(for: BookingRoute.self) { route in
                    switch route {
                    case let .upcoming(booking):
                        // Upcoming taps land on the details screen; its
                        // "Cancel" and "Reschedule" actions push the
                        // respective flows onto this stack.
                        UpcomingBookingView(
                            bookingId: booking.id,
                            onReschedule: { path.append(.rescheduleBooking(booking)) },
                            onCancel: { path.append(.cancelBooking(booking)) }
                        )
                    case let .past(booking):
                        // Past taps land on the session summary. The
                        // summary's CTAs push `WriteReviewView` (leave a
                        // review) or `MakeABooking` (book again with the
                        // same expert) onto this same NavigationStack.
                        BookingSummaryView(
                            bookingId: booking.id,
                            onBookAgain: { seed in
                                if let seed { path.append(.makeBooking(seed)) }
                            },
                            onLeaveReview: { path.append(.writeReview(booking)) }
                        )
                    case let .writeReview(booking):
                        WriteReviewView(
                            bookingId: booking.id,
                            bookingStatus: booking.status,
                            seedExpertName: booking.expertName
                        )
                    case let .makeBooking(seed):
                        MakeABooking(
                            expertId: seed.expertId,
                            expertName: seed.expertName,
                            expertTitle: seed.expertTitle,
                            expertImageURL: seed.expertImageURL
                        )
                    case let .cancelBooking(booking):
                        // On confirm — or "keep booking" — pop back to the
                        // My Bookings root. The list refreshes automatically
                        // on next appear, revealing the newly-cancelled
                        // booking under the past tab.
                        ClientCancellationView(
                            bookingId: booking.id,
                            onKeepBooking: { path.removeAll() },
                            onConfirmCancellation: { _, _ in path.removeAll() }
                        )
                    case let .rescheduleBooking(booking):
                        // On success, pop all the way back to My Bookings
                        // so the list re-fetches with the updated slot.
                        RescheduleView(
                            bookingId: booking.id,
                            onRescheduled: { path.removeAll() }
                        )
                    }
                }
        }
    }

    private var screen: some View {
        ZStack {
            MyBookingsBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                MyBookingsSegmentPicker(selectedTab: $viewModel.selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                content
            }
            // Anchor the content stack to the top — the ZStack was centering
            // the VStack whenever it collapsed to its content size (i.e.
            // loading spinner / error state), leaving the header floating.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MyBookingsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.glowPulse = true }
        .task { await viewModel.load() }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    UpcomingBookingCard(
                        booking: Self.skeletonUpcoming,
                        onJoinCall: {}, onReschedule: {}, onMessage: {}, onCardTap: {}
                    )
                    .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private var loadedContent: some View {
        if viewModel.selectedTab == 0 && viewModel.upcomingBookings.isEmpty {
            UpcomingEmptyState(
                glowPulse: viewModel.glowPulse,
                onExploreExperts: onExploreExperts
            )
        } else {
            ScrollView(showsIndicators: false) {
                if viewModel.selectedTab == 0 {
                    upcomingList.transition(.opacity)
                } else {
                    pastList.transition(.opacity)
                }
            }
            .refreshable { await viewModel.reload() }
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)
        }
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(MyBookingsBrand.onSurface.opacity(0.6))
            Text("Couldn't load bookings")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(MyBookingsBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(MyBookingsBrand.onSurface.opacity(0.6))
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
                    .background(Capsule().fill(Brand.primary))
            }
            .padding(.top, 4)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: Lists

    private var upcomingList: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.upcomingBookings) { booking in
                UpcomingBookingCard(
                    booking: booking,
                    onJoinCall: { onJoinCall(booking) },
                    onReschedule: { onReschedule(booking) },
                    onMessage: { onMessage(booking) },
                    onCardTap: { path.append(.upcoming(booking)) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private var pastList: some View {
        VStack(spacing: 14) {
            ForEach(viewModel.pastBookings) { booking in
                PastBookingCard(
                    booking: booking,
                    onViewSummary: { path.append(.past(booking)) },
                    onPrivateNote: { onPrivateNote(booking) },
                    onLeaveReview: { onLeaveReview(booking) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: Skeleton row

    /// Filler booking used behind `.redacted(.placeholder)` so SwiftUI has
    /// geometry to shimmer over during initial load.
    private static let skeletonUpcoming = UpcomingBooking(
        id: UUID(),
        expertName: "\u{2003}\u{2003}\u{2003}\u{2003}",
        topic: "\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}",
        date: "Jan 1, 2026",
        timeRange: "10:00 AM - 11:00 AM",
        imageURL: "",
        startTime: Date()
    )
}

// MARK: - Previews

#Preview("Upcoming") {
    NavigationStack {
        MyBookingsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    NavigationStack {
        MyBookingsView(viewModel: .previewSeed(upcomingBookings: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Past") {
    NavigationStack {
        MyBookingsView(viewModel: .previewSeed(selectedTab: 1))
    }
    .preferredColorScheme(.dark)
}

/// Hits `/client/bookings` on appear. Token comes from the gitignored
/// `PreviewSecrets.swift`. If that file is missing or empty, the request
/// will 401 and the error view will render.
#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return NavigationStack {
        MyBookingsView()
    }
    .preferredColorScheme(.dark)
}
