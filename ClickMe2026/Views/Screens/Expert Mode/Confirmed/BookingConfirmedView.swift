//
//  BookingConfirmedView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Booking Confirmation Display Model

/// Display-only model for the confirmation screen: the client side of an
/// accepted booking request. All fields are pre-formatted strings intended to
/// be rendered verbatim, built by
/// `ExpertBookingConfirmationContent.confirmation(...)`. Raw dates for the
/// calendar sheet live in `calendarPayload`.
struct BookingConfirmation {
    let clientName: String
    let clientImageURL: String
    let topic: String
    let date: String // e.g. "Oct 24, 2023"
    let time: String // e.g. "10:30 AM"
    let duration: String // e.g. "30 min"
    let meetingTypeLabel: String // e.g. "In-App Voice"
    let meetingTypeIcon: String // SF Symbol name
    let calendarTitle: String // e.g. "ClickMe · Career coaching with Jane D."
    let calendarNotes: String // meeting type, then the client's message
    let calendarPayload: BookingCalendarPayload
}

// MARK: - Booking Confirmed View

struct BookingConfirmedView: View {
    let booking: BookingConfirmation
    var onBackToHome: () -> Void

    @State private var viewModel = BookingConfirmedViewModel()
    @State private var showCalendarEditor = false

    // MARK: Init

    init(
        booking: BookingConfirmation = BookingConfirmation.sample,
        onBackToHome: @escaping () -> Void = {}
    ) {
        self.booking = booking
        self.onBackToHome = onBackToHome
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                BookingConfirmedCheckIcon(
                    scale: viewModel.checkScale,
                    opacity: viewModel.checkOpacity,
                    glowPulse: viewModel.glowPulse
                )
                .padding(.bottom, 28)

                BookingConfirmedHeadline(booking: booking)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
                    .opacity(viewModel.textOpacity)
                    .offset(y: viewModel.textOffset)

                BookingConfirmedCard(booking: booking)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .opacity(viewModel.cardOpacity)
                    .offset(y: viewModel.cardOffset)

                Spacer()

                BookingConfirmedActionButtons(
                    onAddToCalendar: { showCalendarEditor = true },
                    onBackToHome: onBackToHome
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
                .opacity(viewModel.btnOpacity)
                .offset(y: viewModel.btnOffset)
            }
        }
        .onAppear { viewModel.runEntryAnimation() }
        .sheet(isPresented: $showCalendarEditor) {
            CalendarEventEditorSheet(booking: booking) {
                showCalendarEditor = false
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Sample data

extension BookingConfirmation {
    /// Canned display copy — used by the default init and previews.
    static var sample: BookingConfirmation {
        let start = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .minute, value: 60, to: start) ?? start
        return ExpertBookingConfirmationContent.confirmation(
            clientName: "Jane D.",
            clientImageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            topic: "Career coaching",
            start: start,
            end: end,
            meetingType: .inAppVoice,
            clientMessage: "Hi, I would like to talk about moving into product management."
        )
    }
}

// MARK: - Previews

private struct BookingConfirmedPreviewHost: View {
    let destination: BookingConfirmedView
    @State private var path: [Int] = [0]

    var body: some View {
        NavigationStack(path: $path) {
            Color.clear
                .navigationDestination(for: Int.self) { _ in
                    destination
                }
        }
    }
}

#Preview("Booking Confirmed") {
    BookingConfirmedPreviewHost(destination: BookingConfirmedView())
        .preferredColorScheme(.dark)
}

#Preview("Long names") {
    let start = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    let end = Calendar.current.date(byAdding: .minute, value: 60, to: start) ?? start
    return BookingConfirmedPreviewHost(
        destination: BookingConfirmedView(
            booking: ExpertBookingConfirmationContent.confirmation(
                clientName: "Alexandria Montgomery-Featherstonehaugh III",
                clientImageURL: nil,
                topic: "Preparing for a senior product leadership interview and negotiating the offer",
                start: start,
                end: end,
                meetingType: .skypeZoom,
                clientMessage: nil
            )
        )
    )
    .preferredColorScheme(.dark)
}
