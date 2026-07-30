//
//  UpcomingBookingsSessionCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct UpcomingBookingsSessionCard: View {
    let session: UpcomingSession
    var onJoin: () -> Void
    var onMessage: () -> Void
    var onReschedule: () -> Void
    /// Fires when the client-info / date section of the card is tapped.
    /// Scoped so it doesn't intercept taps on the action buttons below.
    var onCardTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Info section (avatar / name / topic / date) — tap opens
            // the booking summary. Buttons below are outside this
            // contentShape so they keep their own tap behaviour.
            infoSection
                .contentShape(Rectangle())
                .onTapGesture { onCardTap() }

            // Join Session — only for isNow
            if session.isWithinJoinWindow {
                Button(action: onJoin) {
                    Text("Join Session")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Brand.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Brand.primary)
                                .shadow(color: Brand.primary.opacity(0.50), radius: 14, x: 0, y: 4)
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
            }

            // Message + Reschedule
            HStack(spacing: 12) {
                actionButton(icon: "bubble.left", label: "Message", action: onMessage)
                actionButton(icon: "clock.arrow.circlepath", label: "Reschedule", action: onReschedule)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.surfaceContainerLow)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Brand.outlineVariant, lineWidth: 1))
        )
    }

    // MARK: - Info section (tap target)

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Avatar | name + topic | earnings
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: session.clientImageURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.10, green: 0.14, blue: 0.12)
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Brand.primary, lineWidth: 2)
                    .shadow(color: Brand.primary.opacity(0.55), radius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.clientName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Brand.onSurface)
                    Text(session.topic)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.earnings)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Brand.primary)
                    Text("EARNINGS")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .tracking(1.0)
                }
            }

            // Date row + NOW badge
            HStack(spacing: 10) {
                if session.isWithinJoinWindow {
                    Text("NOW")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Brand.onPrimary)
                        .tracking(0.8)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Brand.primary)
                            .shadow(color: Brand.primary.opacity(0.55), radius: 5))
                }
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Brand.onSurfaceVariant)
                Text(session.dateLabel)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Brand.onSurface)
            }
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .regular))
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Brand.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Brand.surfaceContainer)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Brand.outlineVariant, lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
