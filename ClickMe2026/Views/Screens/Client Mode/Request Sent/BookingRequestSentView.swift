//
//  BookingRequestSentView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Booking Request Sent View

struct BookingRequestSentView: View {
    @StateObject private var viewModel: BookingRequestSentViewModel

    var onViewBookings: () -> Void
    var onBackToHome: () -> Void

    // MARK: Inits

    /// Runtime init — hydrates from `GET /client/bookings/:id` on appear.
    init(
        bookingId: UUID,
        onViewBookings: @escaping () -> Void = {},
        onBackToHome: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: BookingRequestSentViewModel(bookingId: bookingId))
        self.onViewBookings = onViewBookings
        self.onBackToHome = onBackToHome
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: BookingRequestSentViewModel,
        onViewBookings: @escaping () -> Void = {},
        onBackToHome: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onViewBookings = onViewBookings
        self.onBackToHome = onBackToHome
    }

    // MARK: Body

    var body: some View {
        ZStack {
            BookingRequestSentBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Booking Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BookingRequestSentBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let wasLoaded = viewModel.state == .loaded
            await viewModel.load()
            // Kick off the entry animation only after the copy is settled.
            // Preview seeds arrive already `.loaded` — run animation right
            // away in that case.
            if wasLoaded || viewModel.state == .loaded {
                viewModel.runEntryAnimation()
            }
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
            VStack(spacing: 0) {
                Spacer(minLength: 32)

                BookingRequestSentCheckIcon(
                    scale: viewModel.iconScale,
                    opacity: viewModel.iconOpacity,
                    glowPulse: viewModel.glowPulse
                )
                .padding(.bottom, 28)

                BookingRequestSentHeadline(
                    expertName: viewModel.expertName,
                    opacity: viewModel.bodyOpacity,
                    yOffset: viewModel.bodyOffset
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

                BookingRequestSentDetailsCard(
                    topic: viewModel.topic,
                    dateTime: viewModel.dateTime,
                    opacity: viewModel.cardOpacity,
                    yOffset: viewModel.cardOffset
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

                BookingRequestSentActions(
                    onViewBookings: onViewBookings,
                    onBackToHome: onBackToHome,
                    opacity: viewModel.btnsOpacity,
                    yOffset: viewModel.btnsOffset
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(BookingRequestSentBrand.onSurface)
            Text("Sending your booking…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(BookingRequestSentBrand.onSurface.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(BookingRequestSentBrand.onSurface.opacity(0.6))
            Text("Couldn't load your booking")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(BookingRequestSentBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(BookingRequestSentBrand.onSurface.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task {
                    await viewModel.reload()
                    if viewModel.state == .loaded {
                        viewModel.runEntryAnimation()
                    }
                }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(BookingRequestSentBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Live-fetch bootstrap

/// Bootstraps by hitting `GET /client/bookings?type=upcoming` to grab the
/// soonest real upcoming booking id, then hands off to `BookingRequestSentView`.
private struct LiveFetchBookingRequestSentBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            BookingRequestSentView(bookingId: bookingId)
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
            .background(BookingRequestSentBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BookingRequestSentBrand.bg.ignoresSafeArea())
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

#Preview("Booking Request Sent") {
    PreviewNavHarness(parentText: "Confirm booking", navTitle: "Book a session", rowTitle: "Request sent") {
        BookingRequestSentView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Custom Expert") {
    PreviewNavHarness(parentText: "Confirm booking", navTitle: "Book a session", rowTitle: "Request sent") {
        BookingRequestSentView(viewModel: .previewSeed(
            expertName: "Dr. Marcus Chen",
            topic: "Growth Strategy Session",
            dateTime: "Nov 5, 2024 | 10:00 AM - 11:00 AM"
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "Confirm booking", navTitle: "Book a session", rowTitle: "Request sent") {
        LiveFetchBookingRequestSentBootstrap()
    }
    .preferredColorScheme(.dark)
}
