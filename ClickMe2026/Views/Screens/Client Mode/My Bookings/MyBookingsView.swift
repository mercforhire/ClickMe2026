//
//  MyBookingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

enum PastBookingStatus {
    case completed, cancelled, missed

    var label: String {
        switch self {
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .missed: return "Missed"
        }
    }

    var color: Color {
        switch self {
        case .completed: return Color(red: 0.267, green: 0.965, blue: 0.592)
        case .cancelled: return Color(red: 1.000, green: 0.420, blue: 0.420)
        case .missed: return Color(red: 1.000, green: 0.720, blue: 0.300)
        }
    }
}

struct UpcomingBooking: Identifiable, Hashable {
    /// Server booking UUID from `ClientBookingItem.bookingId`. Needed for
    /// future API mutations (reschedule/cancel).
    let id: UUID
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let imageURL: String
}

struct PastBooking: Identifiable, Hashable {
    let id: UUID
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let status: PastBookingStatus
}

extension PastBookingStatus: Hashable {}

// MARK: - Navigation routes

private enum BookingRoute: Hashable {
    case upcoming(UpcomingBooking)
    case past(PastBooking)
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
                        BookingSummaryView(
                            expertName: booking.expertName,
                            expertImageURL: booking.imageURL,
                            topic: booking.topic,
                            dateTime: "\(booking.date) • \(booking.timeRange)",
                            feedbackStars: 0,
                            feedbackText: nil
                        )
                    case let .past(booking):
                        BookingSummaryView(
                            expertName: booking.expertName,
                            topic: booking.topic,
                            dateTime: "\(booking.date) • \(booking.timeRange)",
                            feedbackStars: booking.status == .completed ? 5 : 0,
                            feedbackText: booking.status == .completed ? nil : nil
                        )
                    }
                }
        }
    }

    private var screen: some View {
        ZStack {
            MyBookingsBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("My bookings")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(MyBookingsBrand.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                    .padding(.bottom, 20)

                MyBookingsSegmentPicker(selectedTab: $viewModel.selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
                    .background(Capsule().fill(Color(red: 0.267, green: 0.965, blue: 0.592)))
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
        imageURL: ""
    )
}

// MARK: - Previews

#Preview("Upcoming") {
    MyBookingsView(viewModel: .previewSeed())
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    MyBookingsView(viewModel: .previewSeed(upcomingBookings: []))
        .preferredColorScheme(.dark)
}

#Preview("Past") {
    MyBookingsView(viewModel: .previewSeed(selectedTab: 1))
        .preferredColorScheme(.dark)
}

/// Hits `/client/bookings` on appear. Token comes from the gitignored
/// `PreviewSecrets.swift`. If that file is missing or empty, the request
/// will 401 and the error view will render.
#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return MyBookingsView()
        .preferredColorScheme(.dark)
}
