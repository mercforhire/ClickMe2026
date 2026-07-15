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

struct UpcomingBooking: Identifiable {
    let id = UUID()
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let imageURL: String
}

struct PastBooking: Identifiable {
    let id = UUID()
    let expertName: String
    let topic: String
    let date: String
    let timeRange: String
    let status: PastBookingStatus
}

// MARK: - My Bookings View

struct MyBookingsView: View {

    @StateObject private var viewModel: MyBookingsViewModel

    // MARK: Callbacks

    var onJoinCall: (UpcomingBooking) -> Void
    var onReschedule: (UpcomingBooking) -> Void
    var onMessage: (UpcomingBooking) -> Void
    var onViewSummary: (PastBooking) -> Void
    var onPrivateNote: (PastBooking) -> Void
    var onLeaveReview: (PastBooking) -> Void
    var onExploreExperts: () -> Void

    // MARK: Init

    init(
        viewModel: MyBookingsViewModel = MyBookingsViewModel(),
        onJoinCall: @escaping (UpcomingBooking) -> Void = { _ in },
        onReschedule: @escaping (UpcomingBooking) -> Void = { _ in },
        onMessage: @escaping (UpcomingBooking) -> Void = { _ in },
        onViewSummary: @escaping (PastBooking) -> Void = { _ in },
        onPrivateNote: @escaping (PastBooking) -> Void = { _ in },
        onLeaveReview: @escaping (PastBooking) -> Void = { _ in },
        onExploreExperts: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onJoinCall = onJoinCall
        self.onReschedule = onReschedule
        self.onMessage = onMessage
        self.onViewSummary = onViewSummary
        self.onPrivateNote = onPrivateNote
        self.onLeaveReview = onLeaveReview
        self.onExploreExperts = onExploreExperts
    }

    // MARK: Body

    var body: some View {
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
        .onAppear { viewModel.glowPulse = true }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if viewModel.selectedTab == 0 && viewModel.upcomingBookings.isEmpty {
            UpcomingEmptyState(
                glowPulse: viewModel.glowPulse,
                onExploreExperts: onExploreExperts
            )
        } else {
            ScrollView(showsIndicators: false) {
                if viewModel.selectedTab == 0 {
                    upcomingList
                        .transition(.opacity)
                } else {
                    pastList
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)
        }
    }

    // MARK: Lists

    private var upcomingList: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.upcomingBookings) { booking in
                UpcomingBookingCard(
                    booking: booking,
                    onJoinCall: { onJoinCall(booking) },
                    onReschedule: { onReschedule(booking) },
                    onMessage: { onMessage(booking) }
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
                    onViewSummary: { onViewSummary(booking) },
                    onPrivateNote: { onPrivateNote(booking) },
                    onLeaveReview: { onLeaveReview(booking) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Previews

#Preview("Upcoming") {
    MyBookingsView()
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    MyBookingsView(viewModel: MyBookingsViewModel(upcomingBookings: []))
        .preferredColorScheme(.dark)
}

#Preview("Past") {
    MyBookingsView(viewModel: MyBookingsViewModel(selectedTab: 1))
        .preferredColorScheme(.dark)
}
