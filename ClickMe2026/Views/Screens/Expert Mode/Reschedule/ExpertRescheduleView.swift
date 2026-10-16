//
//  ExpertRescheduleView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Expert Reschedule View

/// Expert-side counterpart to `RescheduleView`. Same layout — booking card
/// (showing the client), calendar, time-slot picker, optional message,
/// submit — but the data flow is expert-scoped:
///
/// - Booking detail: `GET /expert/bookings/:id/details`
/// - Availability: `GET /experts/:id/availability` against the expert's
///   own user id (their published schedule).
/// - Submit: `PATCH /expert/bookings/:id/reschedule`
///
/// The subviews under `Client Mode/Reschedule/Subviews/` are display-only
/// and reused as-is. The `RescheduleExpertCard`'s `expertName` slot is
/// (semantically loose) carrying the client's name on this side.
struct ExpertRescheduleView: View {

    @StateObject private var viewModel: ExpertRescheduleViewModel
    @FocusState private var messageFocused: Bool

    /// Fires after the API call succeeds. Callers use it to pop the
    /// NavigationStack back to the booking summary / list.
    var onRescheduled: () -> Void

    // MARK: Init

    init(
        bookingId: UUID,
        onRescheduled: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: ExpertRescheduleViewModel(bookingId: bookingId))
        self.onRescheduled = onRescheduled
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: ExpertRescheduleViewModel,
        onRescheduled: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onRescheduled = onRescheduled
    }

    // MARK: Body

    var body: some View {
        ZStack {
            RescheduleBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Reschedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RescheduleBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .alert(
            "Couldn't reschedule booking",
            isPresented: Binding(
                get: { viewModel.submitError != nil },
                set: { if !$0 { viewModel.submitError = nil } }
            ),
            presenting: viewModel.submitError
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
            loadedContent
        }
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                RescheduleExpertCard(booking: viewModel.booking)

                RescheduleCalendarCard(
                    monthLabel: viewModel.monthYearLabel(viewModel.currentMonth),
                    cells: viewModel.monthCells(),
                    calendar: viewModel.calendar,
                    isSelected: { viewModel.isSelected($0) },
                    isBookable: { viewModel.hasSlots(on: $0) },
                    onPrevMonth: { viewModel.shiftMonth(-1) },
                    onNextMonth: { viewModel.shiftMonth(1) },
                    onSelectDay: { viewModel.select(date: $0) }
                )

                if let availabilityError = viewModel.availabilityError {
                    Text(availabilityError)
                        .font(.brand(.caption, weight: .medium))
                        .foregroundColor(RescheduleBrand.onSurfaceVar)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let label = viewModel.currentSessionLabel {
                    currentSessionBanner(label)
                }

                RescheduleTimeSlotsCard(
                    slots: viewModel.slotsForSelectedDate,
                    selectedTime: viewModel.selectedTime,
                    isCurrent: { viewModel.isCurrentSlot($0) },
                    onSelect: { viewModel.select(time: $0) }
                )

                RescheduleMessageCard(
                    text: $viewModel.message,
                    isFocused: $messageFocused
                )

                RescheduleSubmitButton(
                    action: {
                        if let bid = viewModel.bookingId,
                           !CallCenter.shared.attemptModifyBooking(bid, actionDescription: "reschedule this session") {
                            return
                        }
                        Task { await viewModel.submit(onSuccess: onRescheduled) }
                    },
                    isLoading: viewModel.isSubmitting
                )
                .padding(.top, 4)
                .disabled(viewModel.isSubmitting || viewModel.selectedTime == nil)
                .opacity(viewModel.selectedTime == nil ? 0.55 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        // Blocks re-taps on the calendar / time-slot grid / submit
        // button while the reschedule request is in flight. The submit
        // button's internal spinner provides the "still working"
        // feedback.
        .disabled(viewModel.isSubmitting)
        .opacity(viewModel.isSubmitting ? 0.55 : 1.0)
    }

    /// "Current: Wed, Jul 10 · 10:00 AM" pill shown above the time-slot
    /// grid. Anchors the expert to what they're rescheduling *from*.
    private func currentSessionBanner(_ label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.caption.weight(.semibold))
                .foregroundColor(.orange.opacity(0.9))
            Text("Current: \(label)")
                .font(.brand(.caption, weight: .medium))
                .foregroundColor(RescheduleBrand.onSurface)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(RescheduleBrand.onSurface)
            Text("Loading booking…")
                .font(.brand(.caption))
                .foregroundColor(RescheduleBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(RescheduleBrand.onSurfaceVar)
            Text("Couldn't load booking")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(RescheduleBrand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(RescheduleBrand.onSurfaceVar)
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
                    .background(Capsule().fill(RescheduleBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Live-fetch bootstrap

/// Picks the first upcoming expert booking to preview the reschedule
/// flow against a real record.
private struct LiveFetchExpertRescheduleBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            ExpertRescheduleView(bookingId: bookingId)
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
            .background(RescheduleBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RescheduleBrand.bg.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
        do {
            let response = try await ClickMeAPI.shared.getExpertBookings(type: .upcoming, page: 1, limit: 20)
            guard let soonest = response.data.bookings
                .sorted(by: { $0.session.startTime < $1.session.startTime })
                .first
            else {
                errorMessage = "No expert bookings on this account."
                return
            }
            bookingId = soonest.bookingId
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Live Fetch") {
    NavigationStack {
        LiveFetchExpertRescheduleBootstrap()
    }
    .preferredColorScheme(.dark)
}

#Preview("Reschedule") {
    NavigationStack {
        ExpertRescheduleView(viewModel: ExpertRescheduleViewModel())
    }
    .preferredColorScheme(.dark)
}
