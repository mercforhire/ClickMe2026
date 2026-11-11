//
//  UpcomingBookingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Booking Details View

struct UpcomingBookingView: View {

    @StateObject private var viewModel: UpcomingBookingViewModel
    @ObservedObject private var callCenter = CallCenter.shared

    /// Override for the JOIN CALL / Open in {provider} action. `nil` (the
    /// default for every caller) means the screen starts the call itself through
    /// `CallCenter.startCall`, so the button works however the screen was opened
    /// (My Bookings, a push tap, a chat row, Explore, Payments) with no caller wiring.
    var onJoinCall: (() -> Void)?
    /// Overrides for the Reschedule and Cancel actions. `nil` means the screen
    /// pushes its own `HomeRoute` on the tab's path, and hides the action in a
    /// shell that does not host the client flows. My Bookings passes both.
    var onReschedule: (() -> Void)?
    var onCancel: (() -> Void)?
    var onCopyLink: () -> Void

    @Environment(\.homeNavigationPath) private var homeNavigationPath
    @Environment(\.hostsClientBookingFlows) private var hostsClientBookingFlows

    @State private var showAcceptRescheduleConfirmation = false
    @State private var showDeclineReschedulePrompt = false
    @State private var declineRescheduleReason = ""

    // MARK: Inits

    /// Runtime init — hydrates from `GET /client/bookings/:id` on appear.
    init(
        bookingId: UUID,
        onJoinCall: (() -> Void)? = nil,
        onReschedule: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onCopyLink: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: UpcomingBookingViewModel(bookingId: bookingId))
        self.onJoinCall = onJoinCall
        self.onReschedule = onReschedule
        self.onCancel = onCancel
        self.onCopyLink = onCopyLink
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: UpcomingBookingViewModel,
        onJoinCall: (() -> Void)? = nil,
        onReschedule: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onCopyLink: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onJoinCall = onJoinCall
        self.onReschedule = onReschedule
        self.onCancel = onCancel
        self.onCopyLink = onCopyLink
    }

    // MARK: Body

    var body: some View {
        ZStack {
            UpcomingBookingBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Upcoming Booking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(UpcomingBookingBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.appeared() }
        .confirmationDialog(
            "Accept the proposed reschedule?",
            isPresented: $showAcceptRescheduleConfirmation,
            titleVisibility: .visible
        ) {
            Button("Accept New Time") {
                Task { await viewModel.responder.accept() }
            }
            Button("Keep Current Time", role: .cancel) {}
        } message: {
            Text(viewModel.acceptDialogMessage)
        }
        .alert("Decline reschedule", isPresented: $showDeclineReschedulePrompt) {
            TextField("Optional reason", text: $declineRescheduleReason)
            Button("Decline New Time", role: .destructive) {
                let reason = declineRescheduleReason
                declineRescheduleReason = ""
                Task { await viewModel.responder.decline(reason: reason) }
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
                get: { viewModel.responder.apiError != nil },
                set: { if !$0 { viewModel.responder.apiError = nil } }
            ),
            presenting: viewModel.responder.apiError
        ) { _ in
            Button("Back to Booking", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        // The call surface is hosted by the shell; this screen only surfaces a
        // join failure from CallCenter's shared `joinError` (the My Bookings
        // root may present it too).
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
        .micPermissionDeniedAlert(isPresented: Binding(
            get: { callCenter.micPermissionDenied },
            set: { if !$0 { callCenter.micPermissionDenied = false } }
        ))
    }

    // MARK: Secondary actions

    /// Reschedule and Cancel exist only where something can handle them: a
    /// caller that supplied both closures, or a shell that renders the
    /// `HomeRoute` flows. Inside the expert shell (chat rows reach this
    /// screen) those routes are `EmptyView()` stubs, so the buttons are hidden.
    private var offersClientActions: Bool {
        hostsClientBookingFlows || (onReschedule != nil && onCancel != nil)
    }

    private func rescheduleTapped() {
        if let onReschedule {
            onReschedule()
        } else {
            homeNavigationPath?.push(HomeRoute.rescheduleBooking(bookingId: viewModel.bookingId))
        }
    }

    private func cancelTapped() {
        if let onCancel {
            onCancel()
        } else {
            homeNavigationPath?.push(HomeRoute.cancelBooking(bookingId: viewModel.bookingId))
        }
    }

    // MARK: Content router

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

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                UpcomingBookingStatusRow(pill: viewModel.statusPill, bookingID: viewModel.bookingIDLabel)

                if let proposal = viewModel.pendingProposal,
                   let currentStart = viewModel.startTime
                {
                    RescheduleResponseCard(
                        proposal: proposal,
                        currentStart: currentStart,
                        isSubmitting: viewModel.responder.isSubmitting,
                        onAccept: { showAcceptRescheduleConfirmation = true },
                        onDecline: { showDeclineReschedulePrompt = true }
                    )
                }

                UpcomingBookingExpertCard(
                    expertName: viewModel.expertName,
                    expertTitle: viewModel.expertTitle,
                    expertImageURL: viewModel.expertImageURL
                )

                UpcomingBookingTopicCard(
                    topic: viewModel.topic,
                    consultationFee: viewModel.consultationFee
                )

                UpcomingBookingDateTimeRow(
                    date: viewModel.date,
                    timeRange: viewModel.timeRange
                )

                if let timezone = viewModel.expertTimezone {
                    timezoneRow(timezone: timezone)
                }

                if let pill = paymentStatusPill {
                    pill
                }

                if viewModel.showsJoinCard {
                    // Ticks once a minute so the button enables as the start
                    // time crosses the window edge, with no pull-to-refresh.
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        UpcomingBookingJoinCard(
                            meetingType: viewModel.meetingType,
                            joinLink: viewModel.joinLink,
                            isJoinEnabled: viewModel.joinWindowOpen(at: context.date),
                            onJoinCall: onJoinCall ?? { viewModel.startCall() },
                            onCopyLink: onCopyLink
                        )
                    }
                } else {
                    pendingApprovalBanner
                }

                if !viewModel.preparationNote.isEmpty {
                    UpcomingBookingPrepNotesCard(
                        preparationNote: viewModel.preparationNote
                    )
                }

                // Cancel hides once the server would refuse it (D-13), so this
                // ticks once a minute like the Join card.
                if offersClientActions {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        UpcomingBookingSecondaryActions(
                            showsCancel: UpcomingActionPolicy.canShowCancel(
                                status: viewModel.bookingStatus,
                                end: viewModel.endTime,
                                now: context.date
                            ),
                            onReschedule: { rescheduleTapped() },
                            onCancel: { cancelTapped() }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 48)
        }
    }

    // MARK: Pending-approval banner

    /// Rendered in place of the Join card while the booking is
    /// `pending_approval`. Explains why no join affordance is present
    /// and hints at the expected next step.
    private var pendingApprovalBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "hourglass")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.orange)
                Text("Waiting for expert to accept")
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(UpcomingBookingBrand.onSurface)
                Spacer()
            }
            Text("You'll get a notification once \(viewModel.expertName.isEmpty ? "the expert" : viewModel.expertName) confirms this session. The Join Call option unlocks then.")
                .font(.brand(.caption, weight: .regular))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.orange.opacity(0.45), lineWidth: 1))
        )
    }

    // MARK: Small info rows

    /// Renders a small pill reflecting the server's `payment_status`:
    /// - `held` → amber "Hold placed — charged after your session" (Phase 27
    ///   lifecycle: auth exists, capture runs post-session).
    /// - `captured` → green "Paid".
    /// - `refunded` → muted "Refunded".
    /// - `none` / `nil` → renders nothing (free sessions, non-financial
    ///   bookings).
    private var paymentStatusPill: AnyView? {
        switch viewModel.paymentStatus {
        case "held":
            return AnyView(pillRow(
                iconName: "lock.fill",
                text: "Hold placed — charged after your session",
                tint: .orange
            ))
        case "captured":
            return AnyView(pillRow(
                iconName: "checkmark.seal.fill",
                text: "Paid",
                tint: UpcomingBookingBrand.brandGreen
            ))
        case "refunded":
            return AnyView(pillRow(
                iconName: "arrow.uturn.backward",
                text: "Refunded",
                tint: UpcomingBookingBrand.onSurfaceVar
            ))
        default:
            return nil
        }
    }

    private func pillRow(iconName: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption.weight(.semibold))
                .foregroundColor(tint)
            Text(text)
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(tint)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(tint.opacity(0.12)))
        .padding(.horizontal, 4)
    }

    private func timezoneRow(timezone: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .font(.caption.weight(.medium))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            Text("Expert timezone: \(timezone)")
                .font(.brand(.caption, weight: .regular))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: Loading + error states

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(UpcomingBookingBrand.onSurface)
            Text("Loading booking…")
                .font(.brand(.caption))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            Text("Couldn't load booking")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(UpcomingBookingBrand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
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
                    .background(Capsule().fill(UpcomingBookingBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Live-fetch bootstrap

/// Bootstraps by hitting `GET /client/bookings?type=upcoming` to grab the
/// soonest real upcoming booking id, then hands off to `UpcomingBookingView`.
private struct LiveFetchUpcomingBookingBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            UpcomingBookingView(bookingId: bookingId)
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
            .background(UpcomingBookingBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(UpcomingBookingBrand.bg.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
        do {
            let response = try await ClickMeAPI.shared.getClientBookings(type: .upcoming)
            guard let booking = response.data.bookings
                .sorted(by: { $0.startTime < $1.startTime })
                .first
            else {
                errorMessage = "No upcoming bookings found for this account."
                return
            }
            bookingId = booking.bookingId
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("In-app Call") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Booking details") {
        UpcomingBookingView(viewModel: .previewSeed(meetingType: .inAppVoice, joinLink: ""))
    }
    .preferredColorScheme(.dark)
}

#Preview("Skype / Zoom Call") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Booking details") {
        UpcomingBookingView(viewModel: .previewSeed(
            meetingType: .skypeZoom,
            joinLink: "https://zoom.us/j/98237192834"
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Reschedule proposed") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Booking details") {
        UpcomingBookingView(viewModel: .previewSeed(
            bookingStatus: .pendingReschedule,
            reschedule: RescheduleProposal.previewSample(
                initiatedBy: .expert,
                note: "Something came up on my side. Would this time work for you instead?"
            ),
            startTime: Date().addingTimeInterval(3 * 86_400)
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Pending reschedule pill") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Booking details") {
        UpcomingBookingView(viewModel: .previewSeed(bookingStatus: .pendingReschedule))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Booking details") {
        LiveFetchUpcomingBookingBootstrap()
    }
    .preferredColorScheme(.dark)
}
