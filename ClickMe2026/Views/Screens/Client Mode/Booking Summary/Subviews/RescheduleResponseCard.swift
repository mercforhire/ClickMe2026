//
//  RescheduleResponseCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Amber card shown while a reschedule is pending (BOOK-06, D-01).
///
/// One card for every screen that answers a proposal. If the expert proposed,
/// this client is the counterparty and sees Accept New Time and Decline New
/// Time. If the client proposed, the card shows the "Awaiting expert's
/// response" pill with no actions.
///
/// The card owns no logic: the owner presents the accept confirmation and the
/// decline prompt from `onAccept` / `onDecline` and runs `RescheduleResponder`.
struct RescheduleResponseCard: View {

    let proposal: RescheduleProposal
    /// The booking's current slot start, shown as the FROM side.
    let currentStart: Date
    /// True while an accept or decline is in flight.
    let isSubmitting: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var clientIsCounterparty: Bool { proposal.initiatedBy == .expert }

    private var note: String? {
        guard let trimmed = proposal.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return nil }
        return trimmed
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            timeRow
            if let note {
                noteBlock(note)
            }
            if clientIsCounterparty {
                actionButtons
            } else {
                awaitingResponsePill
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange.opacity(0.9))
                .accessibilityHidden(true)
            Text(clientIsCounterparty ? "Expert requested a new time" : "You proposed a new time")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(MyBookingsBrand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
    }

    private var timeRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 10))
        return layout {
            timeBlock(label: "From", value: Self.slotLabel(currentStart))
            Image(systemName: "arrow.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
                .accessibilityHidden(true)
            timeBlock(label: "To", value: Self.slotLabel(proposal.proposedStart))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.brand(.caption2, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
            Text(value)
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(MyBookingsBrand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The note is passed to `Text` as a `String` value, never interpolated into
    /// a literal, so SwiftUI does not parse it as Markdown (T-03-02).
    private func noteBlock(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(clientIsCounterparty ? "Expert's message" : "Your message")
                .font(.brand(.caption2, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
            Text(verbatim: note)
                .font(.brand(.caption, weight: .regular))
                .foregroundColor(MyBookingsBrand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionButtons: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        let slot = Self.slotLabel(proposal.proposedStart)
        return layout {
            Button(action: onDecline) {
                Text("Decline New Time")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Color.red.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.red.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.red.opacity(0.45), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(isSubmitting)
            .accessibilityLabel("Decline New Time, \(slot)")

            Button(action: onAccept) {
                HStack(spacing: 6) {
                    if isSubmitting {
                        ProgressView().tint(MyBookingsBrand.onPrimary).controlSize(.small)
                    }
                    Text("Accept New Time")
                        .font(.brand(.subheadline, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(MyBookingsBrand.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MyBookingsBrand.brandGreen)
                )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(isSubmitting)
            .accessibilityLabel("Accept New Time, \(slot)")
        }
    }

    private var awaitingResponsePill: some View {
        HStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.caption2.weight(.semibold))
            Text("Awaiting expert's response")
                .font(.brand(.caption, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(MyBookingsBrand.onSurfaceVar)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(MyBookingsBrand.cardBg)
                .overlay(Capsule().stroke(MyBookingsBrand.cardBorder, lineWidth: 1))
        )
    }

    // MARK: Formatting

    /// "Wed, Jul 10 · 10:00 AM" — the FROM / TO slot format.
    static func slotLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("Expert proposed") {
    RescheduleResponseCard(
        proposal: RescheduleProposal.previewSample(initiatedBy: .expert, note: "Something came up. Does this time work for you?"),
        currentStart: Date().addingTimeInterval(3 * 86_400),
        isSubmitting: false,
        onAccept: {},
        onDecline: {}
    )
    .padding(20)
    .background(MyBookingsBrand.bg)
    .preferredColorScheme(.dark)
}

#Preview("Client proposed") {
    RescheduleResponseCard(
        proposal: RescheduleProposal.previewSample(initiatedBy: .client, note: nil),
        currentStart: Date().addingTimeInterval(3 * 86_400),
        isSubmitting: false,
        onAccept: {},
        onDecline: {}
    )
    .padding(20)
    .background(MyBookingsBrand.bg)
    .preferredColorScheme(.dark)
}

extension RescheduleProposal {

    /// Sample proposal for previews: five days out, one hour long.
    static func previewSample(initiatedBy: RescheduleInitiator, note: String?) -> RescheduleProposal {
        let start = Date().addingTimeInterval(5 * 86_400)
        return RescheduleProposal(
            proposedStart: start,
            proposedEnd: start.addingTimeInterval(3600),
            proposedTimezone: "America/Toronto",
            initiatedBy: initiatedBy,
            note: note,
            createdAt: Date()
        )
    }
}
