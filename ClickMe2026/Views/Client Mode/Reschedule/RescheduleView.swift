//
//  RescheduleView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
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

    var onSubmit: (Date?, String?, String) -> Void

    // MARK: Init

    init(
        viewModel: RescheduleViewModel = RescheduleViewModel(),
        onSubmit: @escaping (Date?, String?, String) -> Void = { _, _, _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSubmit = onSubmit
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass a booking keep compiling.
    init(
        booking: RescheduleBooking,
        onSubmit: @escaping (Date?, String?, String) -> Void = { _, _, _ in }
    ) {
        self.init(
            viewModel: RescheduleViewModel(booking: booking),
            onSubmit: onSubmit
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            RescheduleBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    RescheduleExpertCard(booking: viewModel.booking)

                    RescheduleCalendarCard(
                        monthLabel: viewModel.monthYearLabel(viewModel.currentMonth),
                        cells: viewModel.monthCells(),
                        calendar: viewModel.calendar,
                        isSelected: { viewModel.isSelected($0) },
                        onPrevMonth: { viewModel.shiftMonth(-1) },
                        onNextMonth: { viewModel.shiftMonth(1) },
                        onSelectDay: { viewModel.select(date: $0) }
                    )

                    RescheduleTimeSlotsCard(
                        slots: viewModel.timeSlots,
                        selectedTime: viewModel.selectedTime,
                        onSelect: { viewModel.select(time: $0) }
                    )

                    RescheduleMessageCard(
                        text: $viewModel.message,
                        isFocused: $messageFocused
                    )

                    RescheduleSubmitButton {
                        onSubmit(viewModel.selectedDate, viewModel.selectedTime, viewModel.message)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Reschedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RescheduleBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Preview harness

private enum ReschedulePreviewRoute: Hashable {
    case reschedule
}

/// Wraps the reschedule screen inside a NavigationStack with a dummy
/// "My Bookings" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct ReschedulePreviewHarness: View {
    let route: ReschedulePreviewRoute
    @State private var path: [ReschedulePreviewRoute]

    init(route: ReschedulePreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Upcoming sessions")
                NavigationLink("Reschedule booking", value: route)
            }
            .navigationTitle("My Bookings")
            .navigationDestination(for: ReschedulePreviewRoute.self) { _ in
                RescheduleView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Reschedule") {
    ReschedulePreviewHarness(route: .reschedule)
        .preferredColorScheme(.dark)
}
