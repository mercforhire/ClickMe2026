//
//  ExpertBookingSummaryView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Local routes

/// Push target for the "My Note" card. Kept private + registered
/// locally on this view so the seed values ride along with the route
/// without any shell-level plumbing.
private struct ExpertPrivateNoteRoute: Hashable {
    let bookingId: UUID
    let clientName: String
    let topic: String
    let dateLabel: String
}

// MARK: - Expert Booking Summary View

/// Pushed when the expert taps an upcoming session card. Renders the
/// booking as seen from the expert's perspective: client identity,
/// session schedule + topic + fee, prep notes (client's message at
/// booking time), and a Message-client CTA that hands off to the shell
/// via `openChatThread`.
///
/// Data source: `GET /expert/bookings/:id/details` → `ExpertBookingDetail`.
struct ExpertBookingSummaryView: View {

    @StateObject private var viewModel: ExpertBookingSummaryViewModel

    @Environment(\.openChatThread) private var openChatThread
    @Environment(\.homeNavigationPath) private var homeNavigationPath

    /// Drives the `.sheet` presenting `ExpertCancellationView`. Flipped
    /// by the Cancel action button; cleared by the sheet's dismiss.
    @State private var showCancellationSheet: Bool = false

    /// Confirmation-dialog state for accepting the pending reschedule.
    @State private var showAcceptRescheduleConfirmation: Bool = false
    /// Alert-with-text-field state for declining the reschedule with
    /// an optional reason.
    @State private var showDeclineReschedulePrompt: Bool = false
    @State private var declineRescheduleReason: String = ""

    // MARK: Init

    init(bookingId: UUID) {
        _viewModel = StateObject(wrappedValue: ExpertBookingSummaryViewModel(bookingId: bookingId))
    }

    /// Preview / test seam.
    init(viewModel: ExpertBookingSummaryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content
        }
        .navigationTitle("Booking Summary")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $showCancellationSheet) {
            cancellationSheet
        }
        .navigationDestination(for: ExpertPrivateNoteRoute.self) { route in
            ExpertBookingNoteView(
                bookingId: route.bookingId,
                clientName: route.clientName,
                topic: route.topic,
                dateLabel: route.dateLabel
            )
        }
        .confirmationDialog(
            "Accept the proposed reschedule?",
            isPresented: $showAcceptRescheduleConfirmation,
            titleVisibility: .visible
        ) {
            Button("Accept") {
                Task { await viewModel.acceptReschedule() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The session will move to the new time your client proposed.")
        }
        .alert(
            "Decline reschedule",
            isPresented: $showDeclineReschedulePrompt
        ) {
            TextField("Optional reason", text: $declineRescheduleReason)
            Button("Decline", role: .destructive) {
                let reason = declineRescheduleReason
                declineRescheduleReason = ""
                Task { await viewModel.declineReschedule(reason: reason) }
            }
            Button("Keep session as-is", role: .cancel) {
                declineRescheduleReason = ""
            }
        } message: {
            Text("The booking will revert to its original time.")
        }
        .alert(
            "Couldn't update booking",
            isPresented: Binding(
                get: { viewModel.rescheduleError != nil },
                set: { if !$0 { viewModel.rescheduleError = nil } }
            ),
            presenting: viewModel.rescheduleError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .keyboardDismissToolbar()
    }

    /// Wraps `ExpertCancellationView` in its own NavigationStack (so the
    /// sheet gets a title bar) and seeds it with the display copy the
    /// screen expects. On success — or "Keep booking" — dismiss the sheet
    /// and pop the summary itself back to the bookings list, since the
    /// underlying record has changed state.
    @ViewBuilder
    private var cancellationSheet: some View {
        if let detail = viewModel.detail {
            NavigationStack {
                ExpertCancellationView(
                    bookingId: detail.bookingId,
                    clientName: detail.client.name ?? "Client",
                    clientImageURL: detail.client.avatarUrl ?? "",
                    sessionTopic: detail.session.topicTitle ?? "Session",
                    dateTime: "\(viewModel.dateLabel) • \(viewModel.timeRangeLabel)",
                    refundType: "full refund",
                    onKeepBooking: { showCancellationSheet = false },
                    onConfirm: { _ in
                        showCancellationSheet = false
                        homeNavigationPath?.pop()
                    }
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
            if let detail = viewModel.detail {
                loadedContent(detail: detail)
            } else {
                loadingContent
            }
        }
    }

    private func loadedContent(detail: ExpertBookingDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                clientHeader(detail: detail)
                statusBadge(detail: detail)

                if let proposal = detail.reschedule {
                    rescheduleCard(detail: detail, proposal: proposal)
                }

                detailsCard(detail: detail)

                if let notes = detail.preparationNotes.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !notes.isEmpty
                {
                    prepNotesCard(text: notes)
                }

                myNoteCard(detail: detail)

                if detail.actions.canMessage {
                    messageClientButton(detail: detail)
                        .padding(.top, 4)
                }

                if detail.actions.canReschedule || detail.actions.canCancel {
                    HStack(spacing: 12) {
                        if detail.actions.canReschedule {
                            secondaryActionButton(
                                icon: "clock.arrow.circlepath",
                                label: "Reschedule"
                            ) {
                                homeNavigationPath?.push(
                                    HomeRoute.expertReschedule(bookingId: detail.bookingId)
                                )
                            }
                        }
                        if detail.actions.canCancel {
                            destructiveActionButton(
                                icon: "xmark.circle",
                                label: "Cancel"
                            ) {
                                showCancellationSheet = true
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Secondary / destructive action buttons

    private func secondaryActionButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                Text(label)
                    .font(.brand(.subheadline, weight: .semibold))
            }
            .foregroundColor(Brand.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Brand.surfaceContainer)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Brand.outlineVariant, lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func destructiveActionButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                Text(label)
                    .font(.brand(.subheadline, weight: .semibold))
            }
            .foregroundColor(Color.red.opacity(0.95))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.red.opacity(0.45), lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Client header

    private func clientHeader(detail: ExpertBookingDetail) -> some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: detail.client.avatarUrl ?? "")) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.14, green: 0.20, blue: 0.16)
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(detail.client.name ?? "Client")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(Brand.onSurface)

                Button {
                    guard let navPath = homeNavigationPath else { return }
                    navPath.push(HomeRoute.peerProfile(
                        userId: detail.client.id,
                        name: detail.client.name ?? "Client",
                        avatarURL: detail.client.avatarUrl ?? ""
                    ))
                } label: {
                    Text("View Profile")
                        .font(.brand(.subheadline, weight: .medium))
                        .foregroundColor(Brand.primary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Status badge

    private func statusBadge(detail: ExpertBookingDetail) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Brand.primary)
                .frame(width: 7, height: 7)
                .shadow(color: Brand.primary.opacity(0.75), radius: 4)
            Text(detail.status.label.uppercased())
                .font(.brand(.caption2, weight: .bold))
                .tracking(0.8)
                .foregroundColor(Brand.onSurface)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Brand.overlayWhite05)
                .overlay(Capsule().stroke(Brand.outlineVariant, lineWidth: 1))
        )
    }

    // MARK: - Details card

    private func detailsCard(detail: ExpertBookingDetail) -> some View {
        VStack(spacing: 0) {
            detailRow(label: "Date") {
                Text(viewModel.dateLabel)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
            }
            rowDivider
            detailRow(label: "Time") {
                Text(viewModel.timeRangeLabel)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
            }
            rowDivider
            detailRow(label: "Duration") {
                Text(viewModel.durationLabel)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
            }
            rowDivider
            detailRow(label: "Topic") {
                Text(detail.session.topicTitle ?? "Session")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                    .multilineTextAlignment(.trailing)
            }
            rowDivider
            detailRow(label: "Meeting Type") {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.meetingTypeIcon)
                        .font(.subheadline)
                        .foregroundColor(Brand.onSurface)
                    Text(viewModel.meetingTypeLabel)
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(Brand.onSurface)
                }
            }
            rowDivider
            detailRow(label: "Consultation Fee") {
                Text(viewModel.feeLabel)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.overlayWhite05)
        )
    }

    private func detailRow<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.overlayWhite60)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle().fill(Brand.overlayWhite10).frame(height: 1)
    }

    // MARK: - Prep notes

    private func prepNotesCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client's message")
                .font(.brand(.caption, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Brand.overlayWhite60)
            Text(text)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.overlayWhite05)
        )
    }

    // MARK: - Reschedule card

    /// Amber-toned banner shown when a reschedule is pending. Renders
    /// three states:
    /// - Client proposed → expert is counterparty → **Accept + Decline**
    ///   actions rendered inline.
    /// - Expert proposed → expert is initiator → "Awaiting response"
    ///   pill, no actions.
    /// - (Either way, current + proposed times shown side-by-side.)
    private func rescheduleCard(
        detail: ExpertBookingDetail,
        proposal: RescheduleProposal
    ) -> some View {
        // The initiator is whoever proposed *most recently* (last-write-
        // wins on race). The counterparty acts; the initiator waits.
        let expertIsCounterparty = proposal.initiatedBy == .client
        let headline = expertIsCounterparty
            ? "Client requested a new time"
            : "You proposed a new time"

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.orange.opacity(0.9))
                Text(headline)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                Spacer()
            }

            rescheduleTimesRow(
                fromDate: detail.session.schedule.startTime,
                toDate: proposal.proposedStart
            )

            if let note = proposal.note?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !note.isEmpty
            {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expertIsCounterparty ? "Client's message" : "Your message")
                        .font(.brand(.caption2, weight: .semibold))
                        .tracking(0.6)
                        .foregroundColor(Brand.onSurfaceVariant)
                    Text(note)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if expertIsCounterparty {
                rescheduleActionButtons
            } else {
                awaitingResponsePill
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func rescheduleTimesRow(fromDate: Date, toDate: Date) -> some View {
        HStack(alignment: .center, spacing: 10) {
            timeBlock(
                label: "From",
                value: viewModel.formattedProposedSlot(RescheduleProposal(
                    proposedStart: fromDate,
                    proposedEnd: fromDate,
                    proposedTimezone: "",
                    initiatedBy: .client,
                    note: nil,
                    createdAt: fromDate
                ))
            )
            Image(systemName: "arrow.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Brand.onSurfaceVariant)
            timeBlock(
                label: "To",
                value: viewModel.formattedProposedSlot(RescheduleProposal(
                    proposedStart: toDate,
                    proposedEnd: toDate,
                    proposedTimezone: "",
                    initiatedBy: .client,
                    note: nil,
                    createdAt: toDate
                ))
            )
            Spacer()
        }
    }

    private func timeBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.brand(.caption2, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Brand.onSurfaceVariant)
            Text(value)
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(Brand.onSurface)
        }
    }

    private var rescheduleActionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showDeclineReschedulePrompt = true
            } label: {
                Text("Decline")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Color.red.opacity(0.95))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.red.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.red.opacity(0.45), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(viewModel.isSubmittingReschedule)

            Button {
                showAcceptRescheduleConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isSubmittingReschedule {
                        ProgressView().tint(Brand.onPrimary).controlSize(.small)
                    }
                    Text("Accept")
                        .font(.brand(.subheadline, weight: .semibold))
                }
                .foregroundColor(Brand.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Brand.primary)
                )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(viewModel.isSubmittingReschedule)
        }
    }

    private var awaitingResponsePill: some View {
        HStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.caption2.weight(.semibold))
            Text("Awaiting client's response")
                .font(.brand(.caption, weight: .semibold))
        }
        .foregroundColor(Brand.onSurfaceVariant)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Brand.overlayWhite05)
                .overlay(Capsule().stroke(Brand.outlineVariant, lineWidth: 1))
        )
    }

    // MARK: - My Note

    /// Full-text private-note surface. Shows the note inline when the
    /// server sent one (so the expert doesn't have to drill in), or an
    /// empty-state ghost prompt otherwise. Tap pushes the editor via
    /// the shell's shared nav path.
    private func myNoteCard(detail: ExpertBookingDetail) -> some View {
        Button(action: { pushPrivateNote(detail: detail) }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Brand.primary)
                    Text("My Note")
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(Brand.onSurface)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.caption.weight(.regular))
                        .foregroundColor(Brand.primary)
                }

                if let note = detail.expertPrivateNote, !note.isEmpty {
                    Text(note)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Tap to jot down your thoughts — only you can see this.")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Brand.primary.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Brand.primary.opacity(0.30), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private func pushPrivateNote(detail: ExpertBookingDetail) {
        guard let homeNavigationPath else { return }
        homeNavigationPath.push(ExpertPrivateNoteRoute(
            bookingId: detail.bookingId,
            clientName: detail.client.name ?? "Client",
            topic: detail.session.topicTitle ?? "Session",
            dateLabel: "\(viewModel.dateLabel) • \(viewModel.timeRangeLabel)"
        ))
    }

    // MARK: - Message CTA

    private func messageClientButton(detail: ExpertBookingDetail) -> some View {
        Button {
            handleMessage(detail: detail)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.fill")
                    .font(.subheadline.weight(.semibold))
                Text("Message Client")
                    .font(.brand(.subheadline, weight: .semibold))
            }
            .foregroundColor(Brand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.primary)
                    .shadow(color: Brand.primary.opacity(0.50), radius: 14, x: 0, y: 4)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    /// `initiateChat` is idempotent — repeat calls return the existing thread.
    /// No-op when rendered outside a shell (previews).
    private func handleMessage(detail: ExpertBookingDetail) {
        guard let openChatThread else { return }
        let clientId = detail.client.id
        let peerName = detail.client.name ?? "Client"
        let peerAvatarURL = detail.client.avatarUrl ?? ""
        Task {
            guard let response = try? await ClickMeAPI.shared.initiateChat(peerId: clientId)
            else { return }
            openChatThread(
                threadId: response.data.threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            )
        }
    }

    // MARK: - Load / error states

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading booking…")
                .font(.brand(.caption))
                .foregroundColor(Brand.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("Couldn't load booking")
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

// MARK: - Live-fetch bootstrap

/// Picks the first upcoming expert booking to preview the summary against
/// a real record. Swallows errors verbosely so the preview surface is
/// useful when the seed account has no upcoming sessions.
private struct LiveFetchExpertBookingSummaryBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            ExpertBookingSummaryView(bookingId: bookingId)
        } else if let errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title.weight(.light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.brand(.caption))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Brand.surface.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Brand.surface.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
        do {
            let response = try await ClickMeAPI.shared.getExpertBookings(type: .upcoming, page: 1, limit: 20)
            if let soonest = response.data.bookings.sorted(by: { $0.session.startTime < $1.session.startTime }).first {
                bookingId = soonest.bookingId
                return
            }
            errorMessage = "No expert bookings on this account."
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Live Fetch") {
    NavigationStack {
        LiveFetchExpertBookingSummaryBootstrap()
    }
    .preferredColorScheme(.dark)
}
