//
//  ExpertRescheduleView.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(RescheduleBrand.onSurfaceVar)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                RescheduleTimeSlotsCard(
                    slots: viewModel.slotsForSelectedDate,
                    selectedTime: viewModel.selectedTime,
                    onSelect: { viewModel.select(time: $0) }
                )

                RescheduleMessageCard(
                    text: $viewModel.message,
                    isFocused: $messageFocused
                )

                RescheduleSubmitButton {
                    if let bid = viewModel.bookingId,
                       !CallCenter.shared.attemptModifyBooking(bid, actionDescription: "reschedule this session") {
                        return
                    }
                    Task { await viewModel.submit(onSuccess: onRescheduled) }
                }
                .padding(.top, 4)
                .disabled(viewModel.isSubmitting || viewModel.selectedTime == nil)
                .opacity(viewModel.selectedTime == nil ? 0.55 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(RescheduleBrand.onSurface)
            Text("Loading booking…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(RescheduleBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(RescheduleBrand.onSurfaceVar)
            Text("Couldn't load booking")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(RescheduleBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(RescheduleBrand.onSurfaceVar)
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
            let response = try await ClickMeAPI.shared.getExpertBookings(page: 1, limit: 20)
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
