//
//  UpcomingBookingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
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

                if let payment = viewModel.paymentStatus, payment != "none" {
                    paymentStatusRow(payment: payment)
                }

                UpcomingBookingJoinCard(
                    joinLink: viewModel.joinLink,
                    onJoinCall: onJoinCall,
                    onCopyLink: onCopyLink
                )

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

    // MARK: Small info rows

    private func timezoneRow(timezone: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            Text("Expert timezone: \(timezone)")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func paymentStatusRow(payment: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(UpcomingBookingBrand.brandGreen)
            Text("Payment: \(payment.capitalized)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurface)
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
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            Text("Couldn't load booking")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
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
                    .background(Capsule().fill(UpcomingBookingBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview harness

private enum UpcomingBookingPreviewRoute: Hashable {
    case confirmed
}

/// Wraps the booking-details screen inside a NavigationStack with a dummy
/// "My Bookings" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct UpcomingBookingPreviewHarness: View {
    let route: UpcomingBookingPreviewRoute
    @State private var path: [UpcomingBookingPreviewRoute]

    init(route: UpcomingBookingPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Upcoming sessions")
                NavigationLink("Booking details", value: route)
            }
            .navigationTitle("My Bookings")
            .navigationDestination(for: UpcomingBookingPreviewRoute.self) { dest in
                switch dest {
                case .confirmed:
                    UpcomingBookingView(viewModel: .previewSeed())
                }
            }
        }
    }
}

// MARK: - Live fetch preview harness

private enum LiveFetchUpcomingRoute: Hashable {
    case details
}

/// Live-fetch harness. Bootstraps by hitting
/// `GET /client/bookings?type=upcoming` to grab the soonest real upcoming
/// booking id, then pushes the details screen which loads that booking via
/// `GET /client/bookings/:id`. Requires `PreviewSecrets.clientBearerToken`.
private struct LiveFetchUpcomingBookingPreviewHarness: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?
    @State private var path: [LiveFetchUpcomingRoute] = [.details]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Upcoming sessions")
                NavigationLink("Booking details", value: LiveFetchUpcomingRoute.details)
            }
            .navigationTitle("My Bookings")
            .navigationDestination(for: LiveFetchUpcomingRoute.self) { _ in
                destinationContent
            }
        }
    }

    @ViewBuilder
    private var destinationContent: some View {
        if let bookingId {
            UpcomingBookingView(bookingId: bookingId)
        } else if let errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.system(size: 13, design: .rounded))
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

#Preview("Booking Details — Confirmed") {
    UpcomingBookingPreviewHarness(route: .confirmed)
        .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    LiveFetchUpcomingBookingPreviewHarness()
        .preferredColorScheme(.dark)
}
