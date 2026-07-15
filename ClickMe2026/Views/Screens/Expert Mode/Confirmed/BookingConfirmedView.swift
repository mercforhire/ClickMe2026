//
//  BookingConfirmedView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Booking Confirmation Display Model

/// Display-only model for the confirmation screen. All fields are
/// pre-formatted strings intended to be rendered verbatim. Raw dates for
/// the calendar sheet live in `BookingCalendarPayload`.
struct BookingConfirmation {
    let expertName: String
    let expertTitle: String
    let expertImageURL: String
    let date: String // e.g. "Oct 24, 2023"
    let time: String // e.g. "10:30 AM"
    let duration: String // e.g. "30 min"
    let isVirtual: Bool
    let meetingNote: String // e.g. "Link will be shared"
}

// MARK: - Booking Confirmed View

struct BookingConfirmedView: View {
    let booking: BookingConfirmation
    let calendarPayload: BookingCalendarPayload
    var onBackToHome: () -> Void

    @State private var viewModel = BookingConfirmedViewModel()
    @State private var showCalendarEditor = false

    // MARK: Init

    init(
        booking: BookingConfirmation = BookingConfirmation.sample,
        calendarPayload: BookingCalendarPayload = BookingCalendarPayload.sample,
        onBackToHome: @escaping () -> Void = {}
    ) {
        self.booking = booking
        self.calendarPayload = calendarPayload
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
            CalendarEventEditorSheet(
                booking: booking,
                calendarPayload: calendarPayload
            ) {
                showCalendarEditor = false
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Sample data

extension BookingConfirmation {
    /// Canned display copy — used by the default init and previews.
    static let sample = BookingConfirmation(
        expertName: "Sophia Carter",
        expertTitle: "Marketing Expert",
        expertImageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuBNGXFUz9EITZoP0I4DBcFI07sjA8tNlCIrSR76s-0ILOQUmHONIn8Yp2KBQ2IYbXMt_zZ0xHTZJPxH0uAp8ynVAMCkrykEOHDlUqrE2PWSbciUg_nc-YOomp7h0MxWPtyBLVU-bL-sd9MBpMd3Rx4lD8S71qzhTd7wGXNljoREV_CApqZsm4S7omcL7oQqg0mO0htR4GFlZGp081dxaw8MX6SymSovWLGw6oOKpZkOK10cVcJmtxrmtNl0N2WbfGyAh-glPpoBV6M",
        date: "Oct 24, 2023",
        time: "10:30 AM",
        duration: "30 min",
        isVirtual: true,
        meetingNote: "Virtual Meeting (Link will be shared)"
    )
}

extension BookingCalendarPayload {
    /// 30-min session starting 30 minutes from "now" — the default that
    /// pairs with `BookingConfirmation.sample`.
    static var sample: BookingCalendarPayload {
        let start = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .minute, value: 30, to: start) ?? start
        return BookingCalendarPayload(startDate: start, endDate: end)
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

#Preview("Face-to-Face Booking") {
    let start = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    let end = Calendar.current.date(byAdding: .minute, value: 60, to: start) ?? start
    return BookingConfirmedPreviewHost(
        destination: BookingConfirmedView(
            booking: BookingConfirmation(
                expertName: "Marcus Chen",
                expertTitle: "Growth Hacker & Analyst",
                expertImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
                date: "Nov 2, 2023",
                time: "2:00 PM",
                duration: "60 min",
                isVirtual: false,
                meetingNote: "Face-to-Face · Downtown Office"
            ),
            calendarPayload: BookingCalendarPayload(startDate: start, endDate: end)
        )
    )
    .preferredColorScheme(.dark)
}
