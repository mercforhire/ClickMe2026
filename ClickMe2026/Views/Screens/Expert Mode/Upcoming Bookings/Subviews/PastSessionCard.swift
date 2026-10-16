//
//  PastSessionCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Single past session card (expert side)

/// Expert equivalent of `PastBookingCard`. Shows the client name +
/// topic + date/time and a status badge. Tapping the info area pushes
/// `ExpertBookingSummaryView`; the "Private Note" button in the
/// actions row pushes `ExpertBookingNoteView` (mirrors the client-side
/// private-note affordance).
struct PastSessionCard: View {
    let session: PastSession
    var onTap: () -> Void
    var onPrivateNote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Info block is its own tap region so the Private Note
            // button below doesn't also fire the summary-tap gesture.
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: URL(string: session.clientImageURL)) { phase in
                        switch phase {
                        case let .success(img): img.resizable().scaledToFill()
                        default:
                            ZStack {
                                Color(red: 0.10, green: 0.14, blue: 0.12)
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.15))
                            }
                        }
                    }
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.clientName)
                            .font(.brand(.callout, weight: .bold))
                            .foregroundColor(Brand.onSurface)
                        Text(session.topic)
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(Brand.onSurfaceVariant)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    BookingStatusBadge(status: session.status)
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption.weight(.regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                    Text("\(session.date), \(session.timeRange)")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            actionsRow

            if let preview = session.privateNotePreview, !preview.isEmpty {
                notePreviewFooter(preview)
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

    /// Compact preview strip shown when a private note exists. Tap
    /// jumps into the note editor (same target as the pencil in
    /// `actionsRow`).
    private func notePreviewFooter(_ text: String) -> some View {
        Button(action: onPrivateNote) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "note.text")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Brand.primary)
                    .padding(.top, 2)
                Text(text)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(Brand.onSurfaceVariant)
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
                    .fill(Brand.primary.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Brand.primary.opacity(0.25), lineWidth: 1))
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
                        .foregroundColor(Brand.primary)
                    Image(systemName: "pencil")
                        .font(.caption.weight(.regular))
                        .foregroundColor(Brand.primary)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}
