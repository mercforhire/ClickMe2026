//
//  UpcomingBookingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//
import SwiftUI

// MARK: - Display model

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
    @State private var viewModel: UpcomingBookingsViewModel

    init(viewModel: UpcomingBookingsViewModel = UpcomingBookingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Convenience initializer for callsites that only need to hand in
    /// navigation callbacks — the sessions themselves come from the API.
    init(
        onJoinSession: @escaping (UpcomingSession) -> Void = { _ in },
        onMessage: @escaping (UpcomingSession) -> Void = { _ in },
        onReschedule: @escaping (UpcomingSession) -> Void = { _ in },
        onEarningsDash: @escaping () -> Void = {},
        onAddSession: @escaping () -> Void = {},
        onUpdateAvailability: @escaping () -> Void = {},
        onViewPastHistory: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: UpcomingBookingsViewModel(
            onJoinSession: onJoinSession,
            onMessage: onMessage,
            onReschedule: onReschedule,
            onEarningsDash: onEarningsDash,
            onAddSession: onAddSession,
            onUpdateAvailability: onUpdateAvailability,
            onViewPastHistory: onViewPastHistory
        ))
    }

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            GreenGlowBlobLayer().ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .animation(.easeInOut(duration: 0.28), value: viewModel.sessions.isEmpty)
        .navigationTitle("Upcoming Sessions")
        .navigationBarTitleDisplayMode(.inline)
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
        Group {
            if viewModel.sessions.isEmpty {
                UpcomingBookingsEmptyState(
                    onUpdateAvailability: viewModel.onUpdateAvailability,
                    onViewPastHistory: viewModel.onViewPastHistory
                )
            } else {
                UpcomingBookingsPopulatedList(
                    sessions: viewModel.sessions,
                    onJoinSession: viewModel.onJoinSession,
                    onMessage: viewModel.onMessage,
                    onReschedule: viewModel.onReschedule,
                    onEarningsDash: viewModel.onEarningsDash,
                    onAddSession: viewModel.onAddSession
                )
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading sessions…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("Couldn't load sessions")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            earnings: "",
            isNow: true
        ),
        UpcomingSession(
            clientName: "Elena Vance",
            clientImageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            topic: "Series B Pitch Review",
            dateLabel: "Thu, Jul 11 • 2:00 PM",
            earnings: "",
            isNow: false
        ),
        UpcomingSession(
            clientName: "Marcus Thorne",
            clientImageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            topic: "Team Conflict Resolution",
            dateLabel: "Fri, Jul 12 • 9:00 AM",
            earnings: "",
            isNow: false
        ),
    ]
}

// MARK: - Previews

#Preview("Upcoming Sessions — Populated") {
    PreviewNavHarness(parentText: "Dashboard overview", navTitle: "Expert Dashboard", rowTitle: "Upcoming Bookings") {
        UpcomingBookingsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Upcoming Sessions — Empty") {
    PreviewNavHarness(parentText: "Dashboard overview", navTitle: "Expert Dashboard", rowTitle: "Upcoming Bookings") {
        UpcomingBookingsView(viewModel: .previewSeed(sessions: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Dashboard overview", navTitle: "Expert Dashboard", rowTitle: "Upcoming Bookings") {
        UpcomingBookingsView()
    }
    .preferredColorScheme(.dark)
}
