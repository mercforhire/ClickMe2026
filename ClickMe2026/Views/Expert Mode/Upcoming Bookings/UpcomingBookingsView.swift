//
//  UpcomingBookingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//
import SwiftUI

// MARK: - Models

struct UpcomingSession: Identifiable {
    let id = UUID()
    let clientName: String
    let clientImageURL: String
    let topic: String
    let dateLabel: String
    let earnings: String
    let isNow: Bool
}

// MARK: - Upcoming Sessions View

struct UpcomingBookingsView: View {
    @State private var sessions: [UpcomingSession]

    var onJoinSession: (UpcomingSession) -> Void
    var onMessage: (UpcomingSession) -> Void
    var onReschedule: (UpcomingSession) -> Void
    var onEarningsDash: () -> Void
    var onAddSession: () -> Void
    var onUpdateAvailability: () -> Void
    var onViewPastHistory: () -> Void

    // MARK: Init

    init(
        sessions: [UpcomingSession] = UpcomingSession.samples,
        onJoinSession: @escaping (UpcomingSession) -> Void = { _ in },
        onMessage: @escaping (UpcomingSession) -> Void = { _ in },
        onReschedule: @escaping (UpcomingSession) -> Void = { _ in },
        onEarningsDash: @escaping () -> Void = {},
        onAddSession: @escaping () -> Void = {},
        onUpdateAvailability: @escaping () -> Void = {},
        onViewPastHistory: @escaping () -> Void = {}
    ) {
        _sessions = State(initialValue: sessions)
        self.onJoinSession = onJoinSession
        self.onMessage = onMessage
        self.onReschedule = onReschedule
        self.onEarningsDash = onEarningsDash
        self.onAddSession = onAddSession
        self.onUpdateAvailability = onUpdateAvailability
        self.onViewPastHistory = onViewPastHistory
    }

    var body: some View {
        ZStack {
            UpcomingBookingsTheme.bg.ignoresSafeArea()
            UpcomingBookingsBlobLayer().ignoresSafeArea()

            VStack(spacing: 0) {
                if sessions.isEmpty {
                    UpcomingBookingsEmptyState(
                        onUpdateAvailability: onUpdateAvailability,
                        onViewPastHistory: onViewPastHistory
                    )
                } else {
                    UpcomingBookingsPopulatedList(
                        sessions: sessions,
                        onJoinSession: onJoinSession,
                        onMessage: onMessage,
                        onReschedule: onReschedule,
                        onEarningsDash: onEarningsDash,
                        onAddSession: onAddSession
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: sessions.isEmpty)
    }
}

// MARK: - Sample data

extension UpcomingSession {
    static let samples: [UpcomingSession] = [
        UpcomingSession(
            clientName: "Julian Reeves",
            clientImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            topic: "Strategic Scaling Strategy",
            dateLabel: "Today • 10:30 AM",
            earnings: "$145.00",
            isNow: true
        ),
        UpcomingSession(
            clientName: "Elena Vance",
            clientImageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            topic: "Series B Pitch Review",
            dateLabel: "Thu, Jul 11 • 2:00 PM",
            earnings: "$210.00",
            isNow: false
        ),
        UpcomingSession(
            clientName: "Marcus Thorne",
            clientImageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            topic: "Team Conflict Resolution",
            dateLabel: "Fri, Jul 12 • 9:00 AM",
            earnings: "$180.00",
            isNow: false
        ),
    ]
}

// MARK: - Previews

/// Wraps the upcoming-bookings screen inside a NavigationStack with a
/// dummy "Expert Dashboard" parent already pushed, so the system back
/// chevron renders in the canvas.
private struct UpcomingBookingsPreviewHost: View {
    let sessions: [UpcomingSession]
    @State private var path: [Int] = [0]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Dashboard overview")
                NavigationLink("Upcoming Bookings", value: 0)
                Text("Incoming Requests")
                Text("Earnings")
            }
            .navigationTitle("Expert Dashboard")
            .navigationDestination(for: Int.self) { _ in
                UpcomingBookingsView(sessions: sessions)
            }
        }
    }
}

#Preview("Upcoming Sessions — Populated") {
    UpcomingBookingsPreviewHost(sessions: UpcomingSession.samples)
        .preferredColorScheme(.dark)
}

#Preview("Upcoming Sessions — Empty") {
    UpcomingBookingsPreviewHost(sessions: [])
        .preferredColorScheme(.dark)
}
