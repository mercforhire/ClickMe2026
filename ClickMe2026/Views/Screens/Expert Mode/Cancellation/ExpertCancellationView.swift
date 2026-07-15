//
//  ExpertCancellationView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Cancellation Reason

enum CancellationReason: String, CaseIterable, Identifiable {
    case none = "Select a reason..."
    case personalEmergency = "Personal Emergency"
    case schedulingConflict = "Scheduling Conflict"
    case technicalIssues = "Technical Issues"
    case other = "Other"

    var id: String {
        rawValue
    }
}

// MARK: - Expert Cancellation View

struct ExpertCancellationView: View {

    @StateObject private var viewModel: ExpertCancellationViewModel

    // MARK: Callbacks

    var onKeepBooking: () -> Void
    var onConfirm: (CancellationReason) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: Init

    init(
        viewModel: ExpertCancellationViewModel = ExpertCancellationViewModel(),
        onKeepBooking: @escaping () -> Void = {},
        onConfirm: @escaping (CancellationReason) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onKeepBooking = onKeepBooking
        self.onConfirm = onConfirm
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass individual content fields keep compiling. Pass a
    /// `bookingId` when wiring from real data so `confirmCancellation`
    /// actually hits `POST /expert/bookings/:id/cancel`; leave nil for
    /// design-only previews.
    init(
        bookingId: UUID? = nil,
        clientName: String = "Marcus Chen",
        clientImageURL: String = ExpertCancellationViewModel.sampleImageURL,
        sessionTopic: String = "Advanced UX Mentorship",
        dateTime: String = "Wed, Oct 25 • 2:00 PM - 3:00 PM",
        refundType: String = "full refund",
        onKeepBooking: @escaping () -> Void = {},
        onConfirm: @escaping (CancellationReason) -> Void = { _ in }
    ) {
        self.init(
            viewModel: ExpertCancellationViewModel(
                bookingId: bookingId,
                clientName: clientName,
                clientImageURL: clientImageURL,
                sessionTopic: sessionTopic,
                dateTime: dateTime,
                refundType: refundType
            ),
            onKeepBooking: onKeepBooking,
            onConfirm: onConfirm
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ExpertCancellationBrand.bg.ignoresSafeArea()
            ExpertCancellationAmbientGlow().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    ExpertCancellationMainCard(
                        clientName: viewModel.clientName,
                        clientImageURL: viewModel.clientImageURL,
                        sessionTopic: viewModel.sessionTopic,
                        dateTime: viewModel.dateTime,
                        refundType: viewModel.refundType,
                        selectedReason: viewModel.selectedReason,
                        onTapReasonPicker: { viewModel.showReasonPicker = true }
                    )

                    ExpertCancellationActions(
                        isCancelling: viewModel.isCancelling,
                        onKeepBooking: { onKeepBooking(); dismiss() },
                        onConfirm: { viewModel.confirmCancellation(onConfirm: onConfirm) }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Confirm Cancellation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ExpertCancellationBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showReasonPicker) {
            ExpertCancellationReasonSheet(
                selectedReason: viewModel.selectedReason,
                onSelect: { viewModel.selectReason($0) }
            )
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
            .presentationBackground(ExpertCancellationBrand.reasonSheetBg)
        }
        .alert(
            "Couldn't cancel booking",
            isPresented: Binding(
                get: { viewModel.apiError != nil },
                set: { if !$0 { viewModel.apiError = nil } }
            ),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
}

// MARK: - Live-fetch bootstrap

/// Fetches the expert's first upcoming booking and hands off to the cancel
/// screen with a real `bookingId`.
private struct LiveFetchExpertCancellationBootstrap: View {
    @State private var resolvedBooking: ExpertBookingItem?
    @State private var errorMessage: String?

    var body: some View {
        if let booking = resolvedBooking {
            ExpertCancellationView(
                bookingId: booking.bookingId,
                clientName: booking.client.name ?? "Client",
                clientImageURL: booking.client.avatarUrl ?? ExpertCancellationViewModel.sampleImageURL,
                sessionTopic: booking.session.topic ?? "Session",
                dateTime: formatDateTime(booking.session.startTime, booking.session.endTime),
                refundType: "full refund"
            )
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
                .task { await resolveBooking() }
        }
    }

    private func resolveBooking() async {
        do {
            let response = try await ClickMeAPI.shared.getExpertBookings(page: 1, limit: 5)
            let now = Date()
            let upcoming = response.data.bookings.first(where: {
                $0.session.endTime > now &&
                    ($0.status.code == .confirmed || $0.status.code == .pendingReschedule || $0.status.code == .inProgress)
            })
            guard let picked = upcoming else {
                errorMessage = "No upcoming bookings — can't test the cancel flow."
                return
            }
            resolvedBooking = picked
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func formatDateTime(_ start: Date, _ end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(dateFormatter.string(from: start)) • \(timeFormatter.string(from: start)) - \(timeFormatter.string(from: end))"
    }
}

// MARK: - Previews

#Preview("Expert Cancellation") {
    PreviewNavHarness(parentText: "Booking details", navTitle: "Upcoming session", rowTitle: "Cancel session") {
        ExpertCancellationView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Partial Refund") {
    PreviewNavHarness(parentText: "Booking details", navTitle: "Upcoming session", rowTitle: "Cancel session") {
        ExpertCancellationView(refundType: "partial refund")
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Booking details", navTitle: "Upcoming session", rowTitle: "Cancel session") {
        LiveFetchExpertCancellationBootstrap()
    }
    .preferredColorScheme(.dark)
}
