//
//  UpcomingBookingCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Single upcoming booking card

struct UpcomingBookingCard: View {
    let booking: UpcomingBooking
    let onJoinCall: () -> Void
    let onReschedule: () -> Void
    let onMessage: () -> Void
    var onCardTap: () -> Void = {}
    /// Tap target for the private-note zone at the bottom of the card
    /// (either the preview footer when a note exists or the "+ Private
    /// Note" ghost when it doesn't). Kept as a no-op default so
    /// callsites that don't wire the note flow don't have to opt out.
    var onPrivateNote: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                expertRow
                dateTimeRow
            }
            .contentShape(Rectangle())
            .onTapGesture { onCardTap() }

            if let reschedule = booking.reschedule {
                rescheduleBadge(reschedule)
            }

            if booking.isPendingExpertApproval {
                // Awaiting-approval bookings never expose Join Call — the
                // expert hasn't accepted, there's no channel. Show a
                // status banner in its place so the client can see WHY
                // the button isn't there.
                pendingApprovalBanner
            } else {
                // Ticks once a minute so the button appears/disappears as
                // the start time crosses the join window boundary, without
                // needing a pull-to-refresh.
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    if booking.isWithinJoinWindow {
                        joinCallButton
                    }
                }
            }
            secondaryActions
            noteZone
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MyBookingsBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MyBookingsBrand.cardBorder, lineWidth: 1))
        )
    }

    // MARK: Reschedule badge

    /// Amber pill shown when the booking has a pending reschedule.
    /// Copy flips based on `initiatedBy` — a client-initiated proposal
    /// reads "Awaiting expert's response" (this client is the
    /// initiator); an expert-initiated one reads "Expert requested a
    /// new time" (this client is the counterparty). Full details +
    /// accept/decline actions live inside the booking summary.
    private func rescheduleBadge(_ reschedule: ReschedulePreview) -> some View {
        let clientIsCounterparty = reschedule.initiatedBy == .expert
        let text = clientIsCounterparty
            ? "Expert proposed a new time · Tap to review"
            : "Reschedule pending expert's response"
        return HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.caption.weight(.semibold))
                .foregroundColor(.orange.opacity(0.9))
            Text(text)
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(MyBookingsBrand.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.45), lineWidth: 1)
                )
        )
    }

    // MARK: Pending-approval banner

    /// Shown in place of the Join Call button when the booking is still
    /// awaiting the expert's decision. Amber tone signals "in progress,
    /// not yet actionable" without alarming (red would read as an error).
    private var pendingApprovalBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "hourglass")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
            Text("Waiting for expert to accept")
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(MyBookingsBrand.onSurface)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.orange.opacity(0.45), lineWidth: 1))
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
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.expertName)
                    .font(.brand(.callout, weight: .regular))
                    .foregroundColor(MyBookingsBrand.onSurfaceVar)
                Text(booking.topic)
                    .font(.brand(.title3, weight: .bold))
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
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
            Text(booking.timeRange)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
        }
    }

    // MARK: Join call

    private var joinCallButton: some View {
        Button(action: onJoinCall) {
            HStack(spacing: 10) {
                Image(systemName: "phone.fill")
                    .font(.callout.weight(.semibold))
                Text("JOIN CALL")
                    .font(.brand(.callout, weight: .bold))
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

    // MARK: Private-note zone

    /// Bottom-of-card affordance for the client's private note. When the
    /// server surfaced a preview, render it inline so the note is
    /// visible without drilling in; otherwise show a ghost "Add note"
    /// pill so writing a note is still one tap away.
    @ViewBuilder
    private var noteZone: some View {
        if let preview = booking.privateNotePreview, !preview.isEmpty {
            Button(action: onPrivateNote) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MyBookingsBrand.brandGreen)
                        .padding(.top, 2)
                    Text(preview)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(MyBookingsBrand.onSurfaceVar)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "pencil")
                        .font(.caption2.weight(.regular))
                        .foregroundColor(MyBookingsBrand.brandGreen)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MyBookingsBrand.brandGreen.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(MyBookingsBrand.brandGreen.opacity(0.25), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onPrivateNote) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.semibold))
                    Text("Add private note")
                        .font(.brand(.caption, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(MyBookingsBrand.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }
            .buttonStyle(.plain)
        }
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
                    .font(.subheadline.weight(.medium))
                Text(label)
                    .font(.brand(.subheadline, weight: .semibold))
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
