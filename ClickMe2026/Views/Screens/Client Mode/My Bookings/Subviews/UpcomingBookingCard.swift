//
//  UpcomingBookingCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single upcoming booking card

struct UpcomingBookingCard: View {
    let booking: UpcomingBooking
    let onJoinCall: () -> Void
    let onReschedule: () -> Void
    let onMessage: () -> Void
    var onCardTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                expertRow
                dateTimeRow
            }
            .contentShape(Rectangle())
            .onTapGesture { onCardTap() }

            // Ticks once a minute so the button appears/disappears as the
            // start time crosses the join window boundary, without needing
            // a pull-to-refresh.
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                if booking.isWithinJoinWindow {
                    joinCallButton
                }
            }
            secondaryActions
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MyBookingsBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MyBookingsBrand.cardBorder, lineWidth: 1))
        )
    }

    // MARK: Expert row

    private var expertRow: some View {
        HStack(spacing: 14) {
            // Avatar with green ring
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [MyBookingsBrand.brandGreen, MyBookingsBrand.brandGreen.opacity(0.55)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .shadow(color: MyBookingsBrand.brandGreen.opacity(0.55), radius: 8)
                    .frame(width: 66, height: 66)

                AsyncImage(url: URL(string: booking.imageURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.12, green: 0.17, blue: 0.14)
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.expertName)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(MyBookingsBrand.onSurfaceVar)
                Text(booking.topic)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(MyBookingsBrand.onSurface)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: Date + time row

    private var dateTimeRow: some View {
        HStack(spacing: 20) {
            Text(booking.date)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
            Text(booking.timeRange)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
        }
    }

    // MARK: Join call

    private var joinCallButton: some View {
        Button(action: onJoinCall) {
            HStack(spacing: 10) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("JOIN CALL")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundColor(MyBookingsBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MyBookingsBrand.brandGreen)
                    .shadow(color: MyBookingsBrand.brandGreen.opacity(0.50), radius: 14, x: 0, y: 4)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: Reschedule + message

    private var secondaryActions: some View {
        HStack(spacing: 12) {
            secondaryButton("Reschedule", icon: "calendar", action: onReschedule)
            secondaryButton("Message", icon: "bubble.left", action: onMessage)
        }
    }

    private func secondaryButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(MyBookingsBrand.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MyBookingsBrand.actionBg)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(MyBookingsBrand.actionBorder, lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
