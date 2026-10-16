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

    var onJoinCall: () -> Void
    var onReschedule: () -> Void
    var onCancel: () -> Void
    var onCopyLink: () -> Void

    // MARK: Inits

    /// Runtime init — hydrates from `GET /client/bookings/:id` on appear.
    init(
        bookingId: UUID,
        onJoinCall: @escaping () -> Void = {},
        onReschedule: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
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
        onJoinCall: @escaping () -> Void = {},
        onReschedule: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
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
        .task { await viewModel.load() }
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
                UpcomingBookingStatusRow(bookingID: viewModel.bookingIDLabel)

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

                if viewModel.isPendingExpertApproval {
                    pendingApprovalBanner
                } else {
                    UpcomingBookingJoinCard(
                        meetingType: viewModel.meetingType,
                        joinLink: viewModel.joinLink,
                        onJoinCall: onJoinCall,
                        onCopyLink: onCopyLink
                    )
                }

                if !viewModel.preparationNote.isEmpty {
                    UpcomingBookingPrepNotesCard(
                        preparationNote: viewModel.preparationNote
                    )
                }

                UpcomingBookingSecondaryActions(
                    onReschedule: onReschedule,
                    onCancel: onCancel
                )
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

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Booking details") {
        LiveFetchUpcomingBookingBootstrap()
    }
    .preferredColorScheme(.dark)
}
