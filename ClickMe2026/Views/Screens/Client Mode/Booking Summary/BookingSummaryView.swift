//
//  BookingSummaryView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Session Summary View

struct BookingSummaryView: View {

    @StateObject private var viewModel: BookingSummaryViewModel

    /// Fires with the resolved expert seed when the user taps "Book Again".
    /// `nil` is passed if the seed isn't ready yet (fetch pending or missing
    /// `expert.id`) — callers typically no-op in that case.
    var onBookAgain: (BookAgainSeed?) -> Void
    var onMessageExpert: () -> Void
    var onLeaveReview: () -> Void
    /// Fires when the user taps the My Note card. The parent
    /// NavigationStack owns the private-note route (`.privateNote` /
    /// `.privateNoteUpcoming` on `MyBookingsView`), so this is a
    /// simple hand-off — no seed needed since the caller already has
    /// the booking in scope.
    var onOpenPrivateNote: () -> Void

    @State private var showAcceptRescheduleConfirmation: Bool = false
    @State private var showDeclineReschedulePrompt: Bool = false
    @State private var declineRescheduleReason: String = ""

    // MARK: Init

    /// Runtime init — hydrates the screen from `GET /client/bookings/:id`
    /// and `GET /bookings/:id/reviews/context`.
    init(
        bookingId: UUID,
        onBookAgain: @escaping (BookAgainSeed?) -> Void = { _ in },
        onMessageExpert: @escaping () -> Void = {},
        onLeaveReview: @escaping () -> Void = {},
        onOpenPrivateNote: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: BookingSummaryViewModel(bookingId: bookingId))
        self.onBookAgain = onBookAgain
        self.onMessageExpert = onMessageExpert
        self.onLeaveReview = onLeaveReview
        self.onOpenPrivateNote = onOpenPrivateNote
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: BookingSummaryViewModel,
        onBookAgain: @escaping (BookAgainSeed?) -> Void = { _ in },
        onMessageExpert: @escaping () -> Void = {},
        onLeaveReview: @escaping () -> Void = {},
        onOpenPrivateNote: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBookAgain = onBookAgain
        self.onMessageExpert = onMessageExpert
        self.onLeaveReview = onLeaveReview
        self.onOpenPrivateNote = onOpenPrivateNote
    }

    /// Resolved seed for the current session — passed to `onBookAgain` when
    /// the button fires. Nil until the booking detail fetch settles.
    private var bookAgainSeed: BookAgainSeed? {
        guard let expertId = viewModel.expertId else { return nil }
        return BookAgainSeed(
            expertId: expertId,
            expertName: viewModel.expertName,
            expertTitle: viewModel.expertTitle,
            expertImageURL: viewModel.expertImageURL
        )
    }

    /// Confirmation-dialog body for the accept-reschedule sheet.
    /// Falls back to the short "session will move" copy when the
    /// proposed slot stays within the current auth window; swaps in
    /// the Phase 27.1 payment-conversion disclosure when the move
    /// would release the current hold and re-schedule the charge to
    /// ~24h before the new session.
    private var acceptRescheduleDialogMessage: String {
        guard viewModel.requiresAcceptRescheduleDisclosure else {
            return "The session will move to the new time the expert proposed."
        }
        var text = "The session will move to the new time the expert proposed.\n\nYour card hold will be released. Because the new time is more than a few days out, we'll release the current payment hold on your card and instead charge it automatically about 24 hours before your new session time. You won't be charged today."
        if viewModel.acceptRescheduleChargesSoon {
            text += "\n\nIf your new session is coming up soon, your card may be charged sooner than 24 hours from now."
        }
        return text
    }

    // MARK: Body

    var body: some View {
        ZStack {
            BookingSummaryBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Session Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BookingSummaryBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
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
            Text(acceptRescheduleDialogMessage)
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if let proposal = viewModel.reschedule,
                   let currentStart = viewModel.currentStartTime
                {
                    rescheduleCard(proposal: proposal, currentStart: currentStart)
                }

                BookingSummaryExpertCard(
                    expertName: viewModel.expertName,
                    expertTitle: viewModel.expertTitle,
                    expertImageURL: viewModel.expertImageURL,
                    topic: viewModel.topic,
                    dateTime: viewModel.dateTime,
                    pricePaid: viewModel.pricePaid,
                    status: viewModel.status
                )

                if viewModel.hasSubmittedReview {
                    BookingSummaryFeedback(
                        feedbackStars: viewModel.feedbackStars,
                        feedbackText: viewModel.feedbackText
                    )
                }

                myNoteCard

                BookingSummaryActions(
                    onBookAgain: { onBookAgain(bookAgainSeed) },
                    onMessageExpert: onMessageExpert
                )
                .padding(.top, 16)

                if !viewModel.hasSubmittedReview {
                    leaveReviewButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(BookingSummaryBrand.onSurface)
            Text("Loading session…")
                .font(.brand(.caption))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
            Text("Couldn't load session")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(BookingSummaryBrand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(BookingSummaryBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Reschedule banner

    /// Amber card shown when a reschedule is pending. Same visual as
    /// the expert-side twin. If the expert proposed → this client is
    /// the counterparty → shows Accept + Decline. If the client
    /// themselves proposed → shows the "Awaiting expert response" pill
    /// with no actions.
    private func rescheduleCard(
        proposal: RescheduleProposal,
        currentStart: Date
    ) -> some View {
        let clientIsCounterparty = proposal.initiatedBy == .expert
        let headline = clientIsCounterparty
            ? "Expert requested a new time"
            : "You proposed a new time"

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.orange.opacity(0.9))
                Text(headline)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(MyBookingsBrand.onSurface)
                Spacer()
            }

            HStack(alignment: .center, spacing: 10) {
                timeBlock(label: "From", value: viewModel.formatSlot(currentStart))
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MyBookingsBrand.onSurfaceVar)
                timeBlock(label: "To", value: viewModel.formatSlot(proposal.proposedStart))
                Spacer()
            }

            if let note = proposal.note?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !note.isEmpty
            {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clientIsCounterparty ? "Expert's message" : "Your message")
                        .font(.brand(.caption2, weight: .semibold))
                        .tracking(0.6)
                        .foregroundColor(MyBookingsBrand.onSurfaceVar)
                    Text(note)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(MyBookingsBrand.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if clientIsCounterparty {
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

    private func timeBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.brand(.caption2, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
            Text(value)
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(MyBookingsBrand.onSurface)
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
                        ProgressView().tint(MyBookingsBrand.onPrimary).controlSize(.small)
                    }
                    Text("Accept")
                        .font(.brand(.subheadline, weight: .semibold))
                }
                .foregroundColor(MyBookingsBrand.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MyBookingsBrand.brandGreen)
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
            Text("Awaiting expert's response")
                .font(.brand(.caption, weight: .semibold))
        }
        .foregroundColor(MyBookingsBrand.onSurfaceVar)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(MyBookingsBrand.cardBg)
                .overlay(Capsule().stroke(MyBookingsBrand.cardBorder, lineWidth: 1))
        )
    }

    /// Full-text "My Note" surface. Renders the note inline when one
    /// exists (so the user doesn't have to drill in to see it), and
    /// shows an empty-state ghost otherwise. Tap fires
    /// `onOpenPrivateNote` — the parent NavigationStack pushes the
    /// editor.
    private var myNoteCard: some View {
        Button(action: onOpenPrivateNote) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(BookingSummaryBrand.brandGreen)
                    Text("My Note")
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(BookingSummaryBrand.onSurface)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.caption.weight(.regular))
                        .foregroundColor(BookingSummaryBrand.brandGreen)
                }

                if let note = viewModel.privateNote, !note.isEmpty {
                    Text(note)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(BookingSummaryBrand.onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Tap to jot down your thoughts — only you can see this.")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(BookingSummaryBrand.onSurfaceVar.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BookingSummaryBrand.brandGreen.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BookingSummaryBrand.brandGreen.opacity(0.30), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    /// CTA surfaced when the user hasn't left a review yet. Delegates to the
    /// caller via `onLeaveReview` so the parent NavigationStack can push the
    /// existing `WriteReviewView` flow.
    private var leaveReviewButton: some View {
        Button(action: onLeaveReview) {
            HStack(spacing: 8) {
                Image(systemName: "star")
                    .font(.subheadline.weight(.semibold))
                Text("Leave a Review")
                    .font(.brand(.subheadline, weight: .semibold))
            }
            .foregroundColor(BookingSummaryBrand.brandGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BookingSummaryBrand.brandGreen.opacity(0.55), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

// MARK: - Live-fetch bootstrap

/// Bootstraps by hitting `GET /client/bookings?type=past` (falling back to
/// upcoming) to pick a real bookingId, then hands off to `BookingSummaryView`.
private struct LiveFetchBookingSummaryBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            BookingSummaryView(bookingId: bookingId)
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
            .background(BookingSummaryBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BookingSummaryBrand.bg.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
        do {
            let past = try await ClickMeAPI.shared.getClientBookings(type: .past)
            if let latest = past.data.bookings.sorted(by: { $0.startTime > $1.startTime }).first {
                bookingId = latest.bookingId
                return
            }
            let upcoming = try await ClickMeAPI.shared.getClientBookings(type: .upcoming)
            if let soonest = upcoming.data.bookings.sorted(by: { $0.startTime < $1.startTime }).first {
                bookingId = soonest.bookingId
                return
            }
            errorMessage = "No bookings found for this account."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("Session Summary — 5 Stars") {
    PreviewNavHarness(parentText: "Past sessions", navTitle: "My Bookings", rowTitle: "Session summary") {
        BookingSummaryView(viewModel: BookingSummaryViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Session Summary — No Review Yet") {
    PreviewNavHarness(parentText: "Past sessions", navTitle: "My Bookings", rowTitle: "Session summary") {
        BookingSummaryView(viewModel: BookingSummaryViewModel(
            feedbackStars: 0,
            feedbackText: nil,
            hasSubmittedReview: false
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "Past sessions", navTitle: "My Bookings", rowTitle: "Session summary") {
        LiveFetchBookingSummaryBootstrap()
    }
    .preferredColorScheme(.dark)
}
