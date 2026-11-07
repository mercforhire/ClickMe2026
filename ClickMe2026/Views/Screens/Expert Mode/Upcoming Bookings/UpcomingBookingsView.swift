//
//  UpcomingBookingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//
import SwiftUI

// MARK: - Display model

struct UpcomingSession: Identifiable, Hashable {
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
    /// Whether the session runs on Agora voice or an external Skype/
    /// Zoom link. Used as an initial hint for the call container so it
    /// renders the right surface immediately (before `POST /join`).
    let meetingType: MeetingType
    /// Wire booking status. Only meaningful hint the expert side needs
    /// to know: `.completed` means this is a rejoin (early hang-up,
    /// scheduled end still ahead) — the call container skips
    /// `confirm-connection` and `end` on that path.
    let status: BookingStatus
    /// Truncated preview of the expert's private note on this booking,
    /// surfaced from `ExpertBookingItem.private_note_preview`. `nil` when
    /// no note has been written.
    let privateNotePreview: String?
    /// Slim reschedule payload — set when `status == .pendingReschedule`.
    /// Drives the amber "Reschedule requested / proposed" badge on the
    /// upcoming card.
    let reschedule: ReschedulePreview?

    /// True when `now` is within one hour of `startTime`. Symmetric so
    /// the button remains available for an hour after start too
    /// (sessions can run late). Deliberately kept in lockstep with
    /// `UpcomingBooking.isWithinJoinWindow` on the client side — the
    /// server's `actions.canJoin` is tighter (~5 min), which was
    /// causing the expert-side button to hide even when the client
    /// side was showing it.
    ///
    /// Note: this struct doesn't carry the booking status, so a
    /// completed-but-not-past session shows the button too — the
    /// server rejects `POST /join` on genuinely-terminal sessions,
    /// which surfaces via CallCenter's join-error alert.
    var isWithinJoinWindow: Bool {
        let delta = startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }
}

// MARK: - Local routes

/// Push targets scoped to this tab (bookings). Registered locally on
/// the view via `.navigationDestination(for: SessionRoute.self)` so
/// bookings-only destinations don't have to bloat the shell-wide
/// `HomeRoute` enum. Shared shell routes (e.g. `.expertBookingSummary`)
/// still flow through `HomeRoute` — the two coexist on the same stack.
private enum SessionRoute: Hashable {
    /// Pushed from the "Private Note" tap on a `PastSessionCard`.
    /// Renders `ExpertBookingNoteView` which loads / saves the
    /// expert's private note via `/bookings/:id/note`.
    case privateNote(PastSession)
    /// Same editor, pushed from the note zone on an upcoming card.
    /// Kept separate so we can seed the header from the upcoming-side
    /// fields (client name / topic / date label) without projecting
    /// into a `PastSession` shape.
    case privateNoteUpcoming(UpcomingSession)
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

            VStack(spacing: 0) {
                UpcomingBookingsSegmentPicker(
                    selectedTab: Binding(
                        get: { viewModel.selectedTab },
                        set: { viewModel.selectedTab = $0 }
                    )
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                content
            }
        }
        .task { await viewModel.load() }
        // Silent refresh on tab-return / navigation-pop — see the
        // `silentReload` docblock for why chrome flicker is worth
        // avoiding here in particular.
        .onAppear { Task { await viewModel.silentReload() } }
        .refreshable { await viewModel.reload() }
        .animation(.easeInOut(duration: 0.28), value: viewModel.sessions.isEmpty)
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)
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
        .micPermissionDeniedAlert(isPresented: Binding(
            get: { callCenter.micPermissionDenied },
            set: { if !$0 { callCenter.micPermissionDenied = false } }
        ))
        .navigationTitle("Upcoming Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SessionRoute.self) { route in
            switch route {
            case let .privateNote(session):
                ExpertBookingNoteView(
                    bookingId: session.bookingId,
                    clientName: session.clientName,
                    topic: session.topic,
                    dateLabel: "\(session.date), \(session.timeRange)"
                )
            case let .privateNoteUpcoming(session):
                ExpertBookingNoteView(
                    bookingId: session.bookingId,
                    clientName: session.clientName,
                    topic: session.topic,
                    dateLabel: session.dateLabel
                )
            }
        }
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

    @ViewBuilder
    private var loadedContent: some View {
        if viewModel.selectedTab == 0 {
            upcomingContent
        } else {
            pastContent
        }
    }

    @ViewBuilder
    private var upcomingContent: some View {
        if viewModel.sessions.isEmpty {
            UpcomingBookingsEmptyState(
                onUpdateAvailability: viewModel.onUpdateAvailability,
                // "View Past History" now switches to the Past tab
                // inline instead of pushing a separate screen — the
                // Past tab holds those sessions right here.
                onViewPastHistory: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectedTab = 1
                    }
                }
            )
        } else {
            UpcomingBookingsPopulatedList(
                sessions: viewModel.sessions,
                onJoinSession: handleJoinSession(for:),
                onMessage: handleMessage(for:),
                onReschedule: viewModel.onReschedule,
                onCardTap: handleCardTap(for:),
                onPrivateNote: handleUpcomingPrivateNoteTap(for:)
            )
        }
    }

    @ViewBuilder
    private var pastContent: some View {
        if viewModel.pastSessions.isEmpty {
            pastEmptyState
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(viewModel.pastSessions) { session in
                        PastSessionCard(
                            session: session,
                            onTap: { handlePastCardTap(for: session) },
                            onPrivateNote: { handlePrivateNoteTap(for: session) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private var pastEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.title.weight(.light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("No past sessions yet")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(Brand.onSurface)
            Text("Completed and cancelled sessions will appear here.")
                .font(.brand(.caption))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading sessions…")
                .font(.brand(.caption))
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
            scheduledEnd: session.endTime,
            meetingType: session.meetingType,
            isRejoin: session.status == .completed
        )
    }

    /// Push the booking-summary detail screen onto the bookings tab's
    /// nav stack. No-ops when rendered outside the expert shell
    /// (previews) — matches the message-button graceful-degradation.
    private func handleCardTap(for session: UpcomingSession) {
        guard let homeNavigationPath else { return }
        homeNavigationPath.push(HomeRoute.expertBookingSummary(bookingId: session.bookingId))
    }

    /// Same destination as the upcoming card — the summary view
    /// renders read-only for terminal statuses on its own.
    private func handlePastCardTap(for session: PastSession) {
        guard let homeNavigationPath else { return }
        homeNavigationPath.push(HomeRoute.expertBookingSummary(bookingId: session.bookingId))
    }

    /// Push the expert-side private-note editor. Same shell nav path
    /// as the summary tap, but keyed to the local `SessionRoute` enum
    /// so this destination stays scoped to the bookings tab.
    private func handlePrivateNoteTap(for session: PastSession) {
        guard let homeNavigationPath else { return }
        homeNavigationPath.push(SessionRoute.privateNote(session))
    }

    /// Same editor, upcoming variant. `UpcomingSession` doesn't project
    /// into `PastSession`, so we route it via the dedicated case.
    private func handleUpcomingPrivateNoteTap(for session: UpcomingSession) {
        guard let homeNavigationPath else { return }
        homeNavigationPath.push(SessionRoute.privateNoteUpcoming(session))
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
                .font(.title.weight(.light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("Couldn't load sessions")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.brand(.subheadline, weight: .semibold))
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
            endTime: Date().addingTimeInterval(60 * 60),
            meetingType: .inAppVoice,
            status: .confirmed,
            privateNotePreview: nil,
            reschedule: nil
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
            endTime: Date().addingTimeInterval(3 * 24 * 3600 + 3600),
            meetingType: .skypeZoom,
            status: .confirmed,
            privateNotePreview: "Discuss H2 hiring plan and headcount ramp.",
            reschedule: nil
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
            endTime: Date().addingTimeInterval(4 * 24 * 3600 + 3600),
            meetingType: .inAppVoice,
            status: .confirmed,
            privateNotePreview: nil,
            reschedule: nil
        ),
    ]
}

// MARK: - Sample past-session data

extension PastSession {
    static let samples: [PastSession] = [
        PastSession(
            bookingId: UUID(),
            clientId: UUID(),
            clientName: "Priya Nair",
            clientImageURL: "https://randomuser.me/api/portraits/women/71.jpg",
            topic: "Product-market fit review",
            date: "Jul 12, 2026",
            timeRange: "3:00 PM – 4:00 PM",
            status: .completed,
            privateNotePreview: "Great conversation — send the ICP deck she asked about."
        ),
        PastSession(
            bookingId: UUID(),
            clientId: UUID(),
            clientName: "Dan Whitby",
            clientImageURL: "https://randomuser.me/api/portraits/men/12.jpg",
            topic: "SaaS pricing coaching",
            date: "Jul 08, 2026",
            timeRange: "11:00 AM – 12:00 PM",
            status: .cancelled,
            privateNotePreview: nil
        ),
        PastSession(
            bookingId: UUID(),
            clientId: UUID(),
            clientName: "Anya Petrov",
            clientImageURL: "https://randomuser.me/api/portraits/women/32.jpg",
            topic: "Executive coaching intro",
            date: "Jul 03, 2026",
            timeRange: "9:00 AM – 9:30 AM",
            status: .missed,
            privateNotePreview: nil
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
