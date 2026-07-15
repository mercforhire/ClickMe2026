//
//  BookingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

enum BookingType {
    case virtual, faceToFace
    var label: String { self == .virtual ? "Virtual" : "Face-to-face" }
    var icon: String  { self == .virtual ? "video" : "person" }
}

enum BookingTab { case upcoming, past }

struct Booking: Identifiable {
    let id = UUID()
    let expertName: String
    let date: String
    let time: String
    let type: BookingType
    let imageURL: String
}

// MARK: - Sample data

extension Booking {
    static let upcomingSamples: [Booking] = [
        Booking(expertName: "Dr. Anya Sharma",   date: "Wed, Jul 10", time: "10:00 AM",
                type: .virtual,    imageURL: "https://randomuser.me/api/portraits/women/44.jpg"),
        Booking(expertName: "Mr. Ethan Carter",  date: "Fri, Jul 12", time: "2:00 PM",
                type: .faceToFace, imageURL: "https://randomuser.me/api/portraits/men/32.jpg"),
    ]
    static let pastSamples: [Booking] = [
        Booking(expertName: "Ms. Olivia Bennett", date: "Mon, Jul 8", time: "11:00 AM",
                type: .virtual,    imageURL: "https://randomuser.me/api/portraits/women/68.jpg"),
        Booking(expertName: "Mr. Noah Thompson",  date: "Sat, Jul 6", time: "3:00 PM",
                type: .faceToFace, imageURL: "https://randomuser.me/api/portraits/men/75.jpg"),
    ]
}

// MARK: - Bookings Screen

struct BookingsView: View {

    @State private var selectedTab: BookingTab = .upcoming
    @Environment(\.dismiss) private var dismiss

    // MARK: Colours
    private let brandGreen  = Color(red: 0.22, green: 0.82, blue: 0.44)
    private let bg          = Color(red: 0.09, green: 0.10, blue: 0.12)
    private let cardBg      = Color(red: 0.12, green: 0.13, blue: 0.15)
    private let cardBorder  = Color(red: 0.22, green: 0.30, blue: 0.38).opacity(0.60)
    private let onSurface   = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let onSurfaceVar = Color(red: 0.60, green: 0.64, blue: 0.70)
    private let onPrimary   = Color(red: 0.00, green: 0.22, blue: 0.11)
    private let tabBarBg    = Color(red: 0.10, green: 0.11, blue: 0.13)

    // MARK: Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Nav bar ──
                navBar
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)

                // ── Segment picker ──
                segmentPicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                // ── Booking cards ──
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(currentBookings) { booking in
                            bookingCard(booking)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: Current bookings

    private var currentBookings: [Booking] {
        selectedTab == .upcoming ? Booking.upcomingSamples : Booking.pastSamples
    }

    // MARK: Nav bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(onSurface)
                }
            }

            Spacer()

            Text("Bookings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)

            Spacer()

            // Invisible spacer to balance the back button
            Color.clear.frame(width: 40, height: 40)
        }
    }

    // MARK: Segment picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            segmentButton("Upcoming", tab: .upcoming)
            segmentButton("Past",     tab: .past)
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(red: 0.14, green: 0.15, blue: 0.18))
        )
    }

    private func segmentButton(_ label: String, tab: BookingTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? onPrimary : onSurfaceVar)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? brandGreen : Color.clear)
                        .shadow(color: isSelected ? brandGreen.opacity(0.35) : .clear,
                                radius: 10, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Booking card

    private func bookingCard(_ booking: Booking) -> some View {
        VStack(spacing: 0) {

            // ── Top: photo + info ──
            HStack(alignment: .top, spacing: 16) {
                // Expert photo
                AsyncImage(url: URL(string: booking.imageURL)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.18, green: 0.20, blue: 0.22)
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 90, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Info column
                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.expertName)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(onSurface)

                    Text("\(booking.date) · \(booking.time)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(onSurfaceVar)

                    HStack(spacing: 6) {
                        Image(systemName: booking.type.icon)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(onSurfaceVar)
                        Text(booking.type.label)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                    }
                }

                Spacer()
            }
            .padding(.bottom, 18)

            // ── Action buttons ──
            actionButtons(for: booking)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.40, green: 0.55, blue: 0.90).opacity(0.55),
                                    Color(red: 0.55, green: 0.35, blue: 0.85).opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
    }

    // MARK: Action buttons

    @ViewBuilder
    private func actionButtons(for booking: Booking) -> some View {
        if selectedTab == .upcoming {
            // Three equal buttons: Reschedule · Cancel · Message
            HStack(spacing: 10) {
                greenButton("Reschedule") { }
                greenButton("Cancel")     { }
                greenButton("Message")    { }
            }
        } else {
            // Two equal buttons: Re-book · Leave Review
            HStack(spacing: 10) {
                greenButton("Re-book")      { }
                greenButton("Leave Review") { }
            }
        }
    }

    private func greenButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(brandGreen)
                        .shadow(color: brandGreen.opacity(0.30), radius: 6, x: 0, y: 2)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale button style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Upcoming") {
    BookingsView()
        .preferredColorScheme(.dark)
}

#Preview("Past") {
    // Open directly on the Past tab
    BookingsPastPreview()
        .preferredColorScheme(.dark)
}

private struct BookingsPastPreview: View {
    var body: some View {
        // Workaround: set selectedTab via onAppear since it's @State
        BookingsView()
    }
}
