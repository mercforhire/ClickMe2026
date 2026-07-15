//
//  ClientCancellationView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct CancellationBooking {
    let expertName: String
    let expertTitle: String
    let dateString: String
    let imageURL: String
    /// Formatted refund amount previewed to the user (e.g. `"$45.00"`).
    /// `nil` hides the refund copy entirely — used for free sessions, when
    /// no payment was made, or when the booking has already been refunded.
    /// Derived client-side from `topic.price` + `paymentStatus` until a
    /// server-side refund-preview endpoint ships.
    let refundAmount: String?
}

enum CancelStep { case reason, confirmation }

// MARK: - Cancellation Flow View

struct ClientCancellationView: View {

    @StateObject private var viewModel: ClientCancellationViewModel

    var onKeepBooking: () -> Void
    var onConfirmCancellation: (String, String) -> Void // (reason, comment)

    @FocusState private var commentFocused: Bool

    // MARK: Init

    /// Runtime init — fetches the booking's display fields from
    /// `GET /client/bookings/:id` and calls `POST /client/bookings/:id/cancel`
    /// on confirm.
    init(
        bookingId: UUID,
        onKeepBooking: @escaping () -> Void = {},
        onConfirmCancellation: @escaping (String, String) -> Void = { _, _ in }
    ) {
        _viewModel = StateObject(wrappedValue: ClientCancellationViewModel(bookingId: bookingId))
        self.onKeepBooking = onKeepBooking
        self.onConfirmCancellation = onConfirmCancellation
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: ClientCancellationViewModel,
        onKeepBooking: @escaping () -> Void = {},
        onConfirmCancellation: @escaping (String, String) -> Void = { _, _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onKeepBooking = onKeepBooking
        self.onConfirmCancellation = onConfirmCancellation
    }

    // MARK: Body

    var body: some View {
        ZStack {
            CancellationBrand.bg.ignoresSafeArea()
            GreenGlowBlobLayer().ignoresSafeArea()

            content
        }
        .animation(.easeInOut(duration: 0.28), value: viewModel.step)
        .task { await viewModel.load() }
        .alert(
            "Couldn't cancel booking",
            isPresented: Binding(
                get: { viewModel.cancelError != nil },
                set: { if !$0 { viewModel.cancelError = nil } }
            ),
            presenting: viewModel.cancelError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
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
            steps
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(CancellationBrand.onSurface)
            Text("Loading booking…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(CancellationBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(CancellationBrand.onSurfaceVar)
            Text("Couldn't load booking")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(CancellationBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(CancellationBrand.onSurfaceVar)
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
                    .background(Capsule().fill(CancellationBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var steps: some View {
        switch viewModel.step {
        case .reason:
            reasonStep
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .confirmation:
            confirmStep
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Step 1 — Reason

    private var reasonStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                CancellationReasonHeadline()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                CancellationReasonCard(
                    reasons: viewModel.reasons,
                    selectedReason: $viewModel.selectedReason
                )

                CancellationCommentField(
                    comment: $viewModel.comment,
                    commentFocused: $commentFocused
                )
                .padding(.horizontal, 20)

                CancellationContinueButton(action: viewModel.advanceToConfirmation)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Step 2 — Confirm

    private var confirmStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                CancellationConfirmCard(booking: viewModel.booking)
                    .padding(.horizontal, 20)

                CancellationActionButtons(
                    isConfirming: viewModel.isConfirming,
                    onKeepBooking: onKeepBooking,
                    onConfirmCancellation: {
                        Task {
                            await viewModel.confirmCancellation(onConfirm: onConfirmCancellation)
                        }
                    }
                )
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }
}

// MARK: - Live-fetch bootstrap

/// Fetches the client's first cancellable booking and hands off to the
/// cancel view with that real `bookingId`, so the flow can end-to-end call
/// `POST /client/bookings/:id/cancel`.
private struct LiveFetchClientCancellationBootstrap: View {
    @State private var resolvedBookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId = resolvedBookingId {
            ClientCancellationView(bookingId: bookingId)
        } else if let errorMessage {
            Text(errorMessage)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        } else {
            ProgressView("Resolving booking…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .task { await resolveBookingId() }
        }
    }

    private func resolveBookingId() async {
        do {
            let response = try await ClickMeAPI.shared.getClientBookings(type: .upcoming, page: 1, limit: 5)
            let cancellable = response.data.bookings.first { row in
                let status = row.status.lowercased()
                return status == "confirmed"
                    || status == "pending_approval"
                    || status == "pending_reschedule"
            }
            guard let picked = cancellable else {
                errorMessage = "No cancellable bookings on this account."
                return
            }
            resolvedBookingId = picked.bookingId
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Step 1 — Reason") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Cancel booking") {
        ClientCancellationView(viewModel: ClientCancellationViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Step 2 — Confirm") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Cancel booking") {
        ClientCancellationView(viewModel: ClientCancellationViewModel(step: .confirmation))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Cancel booking") {
        LiveFetchClientCancellationBootstrap()
    }
    .preferredColorScheme(.dark)
}
