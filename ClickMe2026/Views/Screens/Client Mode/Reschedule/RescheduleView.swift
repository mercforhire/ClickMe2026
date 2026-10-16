//
//  RescheduleView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Booking model

struct RescheduleBooking {
    let expertName: String
    let role: String
    let currentDateLabel: String
    let imageURL: String

    static let sample = RescheduleBooking(
        expertName: "Dr. Anya Sharma",
        role: "Career Mentorship",
        currentDateLabel: "Wednesday, July 10 • 10:00 AM - 10:30 AM",
        imageURL: "https://randomuser.me/api/portraits/women/68.jpg"
    )
}

// MARK: - Reschedule View

struct RescheduleView: View {

    @StateObject private var viewModel: RescheduleViewModel
    @FocusState private var messageFocused: Bool

    /// Set when the user taps submit for a slot that would push the
    /// session past the current auth window (Phase 27.1). Presenting
    /// this triggers the payment-conversion disclosure alert; the
    /// actual submit only fires from the alert's Continue button.
    @State private var pendingDisclosureSlot: BookingTimeSlot?

    /// Fires with no arguments after the API call succeeds. Callers use it
    /// to pop the NavigationStack back to the booking list.
    var onRescheduled: () -> Void

    // MARK: Init

    /// Runtime init — hydrates from `GET /client/bookings/:id` +
    /// `GET /experts/:id/availability` and calls
    /// `PATCH /client/bookings/:id/reschedule` on submit.
    init(
        bookingId: UUID,
        onRescheduled: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: RescheduleViewModel(bookingId: bookingId))
        self.onRescheduled = onRescheduled
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: RescheduleViewModel,
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
        // Payment-conversion disclosure (Phase 27.1). Fires only when
        // the proposed slot lands past the current auth window — the
        // server will void the live hold and re-charge ~24h before
        // the new session. `Continue` runs the actual reschedule
        // submit; `Cancel` leaves the picker untouched.
        .alert(
            "Your card hold will be released",
            isPresented: Binding(
                get: { pendingDisclosureSlot != nil },
                set: { if !$0 { pendingDisclosureSlot = nil } }
            ),
            presenting: pendingDisclosureSlot
        ) { _ in
            Button("Continue") {
                pendingDisclosureSlot = nil
                Task { await viewModel.submit(onSuccess: onRescheduled) }
            }
            Button("Cancel", role: .cancel) {
                pendingDisclosureSlot = nil
            }
        } message: { slot in
            Text(disclosureMessage(for: slot))
        }
    }

    /// Assembles the disclosure body — always shows the base "hold
    /// released → charged ~24h before new session" copy from the
    /// Phase 27.1 spec, and appends the near-term caveat when the
    /// scheduled charge will fire in under ~24 hours.
    private func disclosureMessage(for slot: BookingTimeSlot) -> String {
        var text = "Because you're moving this session more than a few days out, we'll release the current payment hold on your card and instead charge it automatically about 24 hours before your new session time. You won't be charged today."
        if viewModel.chargeWillFireSoon(for: slot) {
            text += "\n\nIf your new session is coming up soon, your card may be charged sooner than 24 hours from now."
        }
        return text
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
                        // Block rescheduling the session currently in
                        // progress — the server would reject with a
                        // race error and the UI would show a confusing
                        // "reschedule failed" state.
                        if let bid = viewModel.bookingId,
                           !CallCenter.shared.attemptModifyBooking(bid, actionDescription: "reschedule this session") {
                            return
                        }
                        // Payment-conversion disclosure (Phase 27.1) —
                        // if the proposed slot lands past the current
                        // auth window, present the disclosure before
                        // submitting; the alert's Continue button runs
                        // the actual submit. Slots that stay within
                        // the window submit straight through.
                        guard let slot = viewModel.selectedTime else { return }
                        if viewModel.requiresPaymentConversionDisclosure(for: slot) {
                            pendingDisclosureSlot = slot
                        } else {
                            Task { await viewModel.submit(onSuccess: onRescheduled) }
                        }
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
        // Dim + block the whole form while the reschedule request is
        // in flight. Prevents double-taps on the calendar, time slot
        // grid, or the submit button itself, and pairs with the
        // button's spinner so the tap-to-completion path has visible
        // feedback throughout.
        .disabled(viewModel.isSubmitting)
        .opacity(viewModel.isSubmitting ? 0.55 : 1.0)
    }

    /// "Current: Wed, Jul 10 · 10:00 AM" pill shown above the time-slot
    /// grid. Anchors the user to what they're rescheduling *from* — the
    /// current slot is intentionally excluded from the available list.
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

/// Bootstraps by hitting `GET /client/bookings?type=upcoming` to grab the
/// soonest real upcoming booking id, then hands off to `RescheduleView`.
/// Custom async logic — sits inside the shared `PreviewNavHarness`.
private struct LiveFetchRescheduleBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            RescheduleView(bookingId: bookingId)
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

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Reschedule booking") {
        LiveFetchRescheduleBootstrap()
    }
    .preferredColorScheme(.dark)
}

#Preview("Reschedule") {
    PreviewNavHarness(parentText: "Upcoming sessions", navTitle: "My Bookings", rowTitle: "Reschedule booking") {
        RescheduleView(viewModel: RescheduleViewModel())
    }
    .preferredColorScheme(.dark)
}
