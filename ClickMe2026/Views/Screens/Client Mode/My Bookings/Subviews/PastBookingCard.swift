//
//  PastBookingCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Single past booking card

struct PastBookingCard: View {
    let booking: PastBooking
    let onViewSummary: () -> Void
    let onPrivateNote: () -> Void
    let onLeaveReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Info section — tap target for "View Summary". Wrapped
            // separately from `actionsRow` so tapping the Private
            // Note / Leave Review buttons doesn't also fire the
            // summary-tap gesture. SwiftUI's `Button` already
            // consumes the tap, but keeping the info block in its
            // own tappable region makes the intent explicit.
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(booking.expertName)
                        .font(.brand(.title3, weight: .bold))
                        .foregroundColor(MyBookingsBrand.onSurface)
                    Spacer()
                    BookingStatusBadge(status: booking.status)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Topic:")
                            .font(.brand(.subheadline, weight: .regular))
                            .foregroundColor(MyBookingsBrand.onSurfaceVar)
                        Text(booking.topic)
                            .font(.brand(.subheadline, weight: .regular))
                            .foregroundColor(MyBookingsBrand.onSurface)
                    }
                    Text("\(booking.date), \(booking.timeRange)")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(MyBookingsBrand.onSurfaceVar)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onViewSummary() }

            actionsRow

            if let preview = booking.privateNotePreview, !preview.isEmpty {
                notePreviewFooter(preview)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MyBookingsBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MyBookingsBrand.cardBorder, lineWidth: 1))
        )
    }

    /// Compact preview strip shown when a private note exists. Tap
    /// jumps into the note editor (same target as the pencil in
    /// `actionsRow`) so the user doesn't have to fish for the icon.
    private func notePreviewFooter(_ text: String) -> some View {
        Button(action: onPrivateNote) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "note.text")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MyBookingsBrand.brandGreen)
                    .padding(.top, 2)
                Text(text)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(MyBookingsBrand.onSurfaceVar)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
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
    }

    private var actionsRow: some View {
        HStack(spacing: 0) {
            Button(action: onPrivateNote) {
                HStack(spacing: 5) {
                    Text("Private Note")
                        .font(.brand(.caption, weight: .semibold))
                        .foregroundColor(MyBookingsBrand.brandGreen)
                    Image(systemName: "pencil")
                        .font(.caption.weight(.regular))
                        .foregroundColor(MyBookingsBrand.brandGreen)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if booking.status == .completed {
                Button(action: onLeaveReview) {
                    Text("Leave Review")
                        .font(.brand(.caption, weight: .bold))
                        .foregroundColor(MyBookingsBrand.onPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(
                            Capsule()
                                .fill(MyBookingsBrand.brandGreen)
                                .shadow(color: MyBookingsBrand.brandGreen.opacity(0.45), radius: 8)
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
    }
}
