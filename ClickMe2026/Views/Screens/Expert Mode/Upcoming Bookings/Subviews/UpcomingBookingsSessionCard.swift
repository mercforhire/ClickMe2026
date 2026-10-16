//
//  UpcomingBookingsSessionCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
    /// Tap target for the private-note zone at the bottom of the card
    /// (preview when a note exists, "+ Add private note" ghost when it
    /// doesn't). No-op default so callers that don't wire notes don't
    /// have to opt out.
    var onPrivateNote: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Info section (avatar / name / topic / date) — tap opens
            // the booking summary. Buttons below are outside this
            // contentShape so they keep their own tap behaviour.
            infoSection
                .contentShape(Rectangle())
                .onTapGesture { onCardTap() }

            if let reschedule = session.reschedule {
                rescheduleBadge(reschedule)
            }

            // Join Session — only for isNow
            if session.isWithinJoinWindow {
                Button(action: onJoin) {
                    Text("Join Session")
                        .font(.brand(.callout, weight: .bold))
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

            noteZone
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
                                .font(.title2)
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
                        .font(.brand(.title3, weight: .bold))
                        .foregroundColor(Brand.onSurface)
                    Text(session.topic)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Hide the whole block in the `.unavailable` fee-source
                // branch (empty string) — per Expert Earnings Breakdown
                // spec §3, never fall back to gross as earnings.
                if !session.earnings.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(session.earnings)
                            .font(.brand(.title3, weight: .bold))
                            .foregroundColor(Brand.primary)
                        Text("EARNINGS")
                            .font(.brand(.caption2, weight: .semibold))
                            .foregroundColor(Brand.onSurfaceVariant)
                            .tracking(1.0)
                    }
                }
            }

            // Date row + NOW badge
            HStack(spacing: 10) {
                if session.isWithinJoinWindow {
                    Text("NOW")
                        .font(.brand(.caption2, weight: .bold))
                        .foregroundColor(Brand.onPrimary)
                        .tracking(0.8)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Brand.primary)
                            .shadow(color: Brand.primary.opacity(0.55), radius: 5))
                }
                Image(systemName: "calendar")
                    .font(.caption.weight(.regular))
                    .foregroundColor(Brand.onSurfaceVariant)
                Text(session.dateLabel)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(Brand.onSurface)
            }
        }
    }

    // MARK: - Reschedule badge

    /// Amber pill shown when a reschedule is pending on this booking.
    /// Copy pivots on `initiatedBy` — client-initiated proposals are
    /// this expert's to accept/decline; expert-initiated ones are
    /// awaiting the client's response.
    private func rescheduleBadge(_ reschedule: ReschedulePreview) -> some View {
        let expertIsCounterparty = reschedule.initiatedBy == .client
        let text = expertIsCounterparty
            ? "Client proposed a new time · Tap to review"
            : "Reschedule pending client's response"
        return HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.caption.weight(.semibold))
                .foregroundColor(.orange.opacity(0.9))
            Text(text)
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(Brand.onSurface)
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

    // MARK: - Private-note zone

    @ViewBuilder
    private var noteZone: some View {
        if let preview = session.privateNotePreview, !preview.isEmpty {
            Button(action: onPrivateNote) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Brand.primary)
                        .padding(.top, 2)
                    Text(preview)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "pencil")
                        .font(.caption2.weight(.regular))
                        .foregroundColor(Brand.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Brand.primary.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Brand.primary.opacity(0.25), lineWidth: 1))
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
                .foregroundColor(Brand.onSurfaceVariant)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Brand.outlineVariant, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.regular))
                Text(label)
                    .font(.brand(.subheadline, weight: .semibold))
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
