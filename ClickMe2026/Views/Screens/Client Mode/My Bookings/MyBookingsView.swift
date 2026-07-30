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
    /// Push path is provided by the enclosing `HomeClientView` via
    /// `@Environment(\.homeNavigationPath)`. When rendered outside the
    /// shell (previews, tests) the fallback `_localPath` provides a
    /// self-contained NavigationStack so the screen still works.
    @Environment(\.homeNavigationPath) private var navPath
    @State private var _localPath: [BookingRoute] = []

    /// Shell-injected action that switches to the Chats tab and pushes
    /// the selected thread. Nil outside a `HomeClientView` shell — in
    /// that case the Message tap silently no-ops.
    @Environment(\.openChatThread) private var openChatThread

    /// Server-side reason the last Join Call attempt failed (e.g.
    /// "Session join window not active"). Bound to
    /// `CallCenter.shared.joinError` so a failed join surfaces an
    /// alert on this surface without keeping the modal on screen.
    @ObservedObject private var callCenter = CallCenter.shared

    // MARK: Callbacks

    var onPrivateNote: (PastBooking) -> Void
    var onLeaveReview: (PastBooking) -> Void
    var onExploreExperts: () -> Void

    // MARK: Init

    init(
        viewModel: MyBookingsViewModel = MyBookingsViewModel(),
        onPrivateNote: @escaping (PastBooking) -> Void = { _ in },
        onLeaveReview: @escaping (PastBooking) -> Void = { _ in },
        onExploreExperts: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onPrivateNote = onPrivateNote
        self.onLeaveReview = onLeaveReview
        self.onExploreExperts = onExploreExperts
    }

    // MARK: Body

    var body: some View {
        Group {
            if navPath != nil {
                screenWithDestinations
            } else {
                NavigationStack(path: $_localPath) {
                    screenWithDestinations
                }
            }
        }
    }

    private var screenWithDestinations: some View {
        screen
            .navigationDestination(for: BookingRoute.self) { route in
                switch route {
                case let .upcoming(booking):
                    // Upcoming taps land on the details screen; its
                    // "Cancel" and "Reschedule" actions push the
                    // respective flows onto this stack.
                    UpcomingBookingView(
                        bookingId: booking.id,
                        onReschedule: { push(.rescheduleBooking(booking)) },
                        onCancel: { push(.cancelBooking(booking)) }
                    )
                case let .past(booking):
                    // Past taps land on the session summary. The
                    // summary's CTAs push `WriteReviewView` (leave a
                    // review) or `MakeABooking` (book again with the
                    // same expert) onto this same NavigationStack.
                    BookingSummaryView(
                        bookingId: booking.id,
                        onBookAgain: { seed in
                            if let seed { push(.makeBooking(seed)) }
                        },
                        onLeaveReview: { push(.writeReview(booking)) }
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
                        onKeepBooking: { popToRoot() },
                        onConfirmCancellation: { _, _ in popToRoot() }
                    )
                case let .rescheduleBooking(booking):
                    // On success, pop all the way back to My Bookings
                    // so the list re-fetches with the updated slot.
                    RescheduleView(
                        bookingId: booking.id,
                        onRescheduled: { popToRoot() }
                    )
                }
            }
    }

    private func push(_ route: BookingRoute) {
        if let navPath {
            navPath.push(route)
        } else {
            _localPath.append(route)
        }
    }

    private func popToRoot() {
        if let navPath {
            navPath.reset()
        } else {
            _localPath.removeAll()
        }
    }

    /// Look up (or create) the chat thread with this booking's expert and
    /// hand off to the shell so the Chats tab opens on that conversation.
    /// `initiateChat` is idempotent — repeat calls return the existing thread.
    /// No-op when rendered outside the shell (previews, tests).
    private func handleMessage(for booking: UpcomingBooking) {
        guard let openChatThread else { return }
        Task {
            guard let response = try? await ClickMeAPI.shared.initiateChat(peerId: booking.expertId)
            else { return }
            openChatThread(
                threadId: response.data.threadId,
                peerName: booking.expertName,
                peerAvatarURL: booking.imageURL
            )
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
        // Call surface is hosted globally by the shell (see
        // `HomeClientView`'s `CallOverlayHost`). This screen only needs
        // to surface a join-failure alert bound to CallCenter's
        // shared `joinError` field.
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
                    onJoinCall: {
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
                    onReschedule: { push(.rescheduleBooking(booking)) },
                    onMessage: { handleMessage(for: booking) },
                    onCardTap: { push(.upcoming(booking)) }
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
                    onViewSummary: { push(.past(booking)) },
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
        expertId: UUID(),
        expertName: "\u{2003}\u{2003}\u{2003}\u{2003}",
        topic: "\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}",
        date: "Jan 1, 2026",
        timeRange: "10:00 AM - 11:00 AM",
        imageURL: "",
        startTime: Date(),
        endTime: Date().addingTimeInterval(30 * 60),
        status: .confirmed
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
