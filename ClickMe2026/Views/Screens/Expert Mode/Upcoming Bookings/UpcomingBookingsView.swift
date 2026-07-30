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
    /// Server `booking_id`. Used to look up the detail record when the
    /// card is tapped (pushes `ExpertBookingSummaryView`).
    let bookingId: UUID
    /// Server UUID of the client on this booking — used to look up (or
    /// create) the chat thread when the Message button is tapped.
    let clientId: UUID
    let clientName: String
    let clientImageURL: String
    let topic: String
    let dateLabel: String
    let earnings: String
    /// Raw UTC start moment — the card uses this to decide whether the
    /// Join Session button is currently in range (within one hour of
    /// start). Mirrors `UpcomingBooking.startTime` on the client side
    /// so the two roles surface the button on the same schedule.
    let startTime: Date
    /// Raw UTC end moment — plumbed through into `MeetingCallView` so
    /// the call screen can drive its "5 min remaining" warning and
    /// soft "scheduled time complete" banner.
    let endTime: Date

    /// True when `now` is within one hour of `startTime`. Symmetric so
    /// the button remains available for an hour after start too
    /// (sessions can run late). Deliberately kept in lockstep with
    /// `UpcomingBooking.isWithinJoinWindow` on the client side — the
    /// server's `actions.canJoin` is tighter (~5 min), which was
    /// causing the expert-side button to hide even when the client
    /// side was showing it.
    var isWithinJoinWindow: Bool {
        let delta = startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }
}

// MARK: - Upcoming Sessions View

struct UpcomingBookingsView: View {
    @State private var viewModel: UpcomingBookingsViewModel

    /// Shell-injected action that switches to the Chats tab and pushes the
    /// selected thread. Nil outside a `HomeExpertView` shell (previews,
    /// isolated tests) — in that case the message tap silently no-ops
    /// rather than crashing, which matches the pre-integration behaviour.
    @Environment(\.openChatThread) private var openChatThread

    /// Shared nav path from the expert shell — used to push the booking
    /// summary destination when a card is tapped.
    @Environment(\.homeNavigationPath) private var homeNavigationPath

    /// Bound to `CallCenter.shared.joinError` so a failed join surfaces
    /// an alert on this screen without keeping any modal on screen.
    /// Actual call presentation lives on the shell's `CallOverlayHost`.
    @ObservedObject private var callCenter = CallCenter.shared

    init(viewModel: UpcomingBookingsViewModel = UpcomingBookingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Convenience initializer for callsites that only need to hand in
    /// navigation callbacks — the sessions themselves come from the API.
    init(
        onJoinSession: @escaping (UpcomingSession) -> Void = { _ in },
        onReschedule: @escaping (UpcomingSession) -> Void = { _ in },
        onUpdateAvailability: @escaping () -> Void = {},
        onViewPastHistory: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: UpcomingBookingsViewModel(
            onJoinSession: onJoinSession,
            onReschedule: onReschedule,
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
        // Call surface is hosted globally by `CallOverlayHost` on
        // `HomeExpertView`. This screen just surfaces a join-failure
        // alert bound to CallCenter's shared error field.
        .alert(
            "Couldn't join session",
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
                    onJoinSession: handleJoinSession(for:),
                    onMessage: handleMessage(for:),
                    onReschedule: viewModel.onReschedule,
                    onCardTap: handleCardTap(for:)
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

    /// Present the in-app voice call as a full-screen cover. The
    /// existing `UpcomingBookingsViewModel.onJoinSession` callback path
    /// was never wired by the shell — this handler bypasses it so the
    /// button actually does something regardless of shell integration.
    private func handleJoinSession(for session: UpcomingSession) {
        CallCenter.shared.startCall(
            bookingId: session.bookingId,
            peerId: session.clientId,
            peerName: session.clientName,
            peerImageURL: session.clientImageURL,
            topic: session.topic,
            scheduledStart: session.startTime,
            scheduledEnd: session.endTime
        )
    }

    /// Push the booking-summary detail screen onto the bookings tab's
    /// nav stack. No-ops when rendered outside the expert shell
    /// (previews) — matches the message-button graceful-degradation.
    private func handleCardTap(for session: UpcomingSession) {
        guard let homeNavigationPath else { return }
        homeNavigationPath.push(HomeRoute.expertBookingSummary(bookingId: session.bookingId))
    }

    /// Look up (or create) the chat thread with this session's client and
    /// hand off to the shell so the Chats tab opens on that conversation.
    /// `initiateChat` is idempotent — repeat calls return the existing thread.
    private func handleMessage(for session: UpcomingSession) {
        guard let openChatThread else { return }
        Task {
            guard let response = try? await ClickMeAPI.shared.initiateChat(peerId: session.clientId)
            else { return }
            openChatThread(
                threadId: response.data.threadId,
                peerName: session.clientName,
                peerAvatarURL: session.clientImageURL
            )
        }
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
            bookingId: UUID(),
            clientId: UUID(),
            clientName: "Julian Reeves",
            clientImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            topic: "Strategic Scaling Strategy",
            dateLabel: "Today • 10:30 AM",
            earnings: "",
            startTime: Date().addingTimeInterval(30 * 60), // in-window
            endTime: Date().addingTimeInterval(60 * 60)
        ),
        UpcomingSession(
            bookingId: UUID(),
            clientId: UUID(),
            clientName: "Elena Vance",
            clientImageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            topic: "Series B Pitch Review",
            dateLabel: "Thu, Jul 11 • 2:00 PM",
            earnings: "",
            startTime: Date().addingTimeInterval(3 * 24 * 3600),
            endTime: Date().addingTimeInterval(3 * 24 * 3600 + 3600)
        ),
        UpcomingSession(
            bookingId: UUID(),
            clientId: UUID(),
            clientName: "Marcus Thorne",
            clientImageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            topic: "Team Conflict Resolution",
            dateLabel: "Fri, Jul 12 • 9:00 AM",
            earnings: "",
            startTime: Date().addingTimeInterval(4 * 24 * 3600),
            endTime: Date().addingTimeInterval(4 * 24 * 3600 + 3600)
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
