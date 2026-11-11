//
//  UpcomingBookingJoinCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Join card
//
// Variant driven by `meetingType`:
//   • .inAppVoice — no link (there's nothing to paste). Renders just the
//     large "JOIN CALL" primary button.
//   • .skypeZoom  — an "Open in {provider}" button above the link row with a
//     copy button. The button runs the same action as JOIN CALL, so the booking
//     goes through `CallCenter.startCall` into the Skype/Zoom session screen,
//     which tracks the time, opens the link and reports `/end` (D-10). This
//     card never opens the expert-supplied URL itself.

struct UpcomingBookingJoinCard: View {
    let meetingType: MeetingType
    let joinLink: String
    /// True while the shared join window is open (`JoinWindow.isOpen`). When
    /// false the Join button stays visible but dimmed and disabled.
    let isJoinEnabled: Bool
    let onJoinCall: () -> Void
    let onCopyLink: () -> Void

    @State private var didCopyLink = false

    var body: some View {
        Group {
            switch meetingType {
            case .inAppVoice:
                inAppJoinButton
            case .skypeZoom:
                VStack(spacing: 16) {
                    openMeetingButton
                    linkRow
                }
            }
        }
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }

    // MARK: In-app variant

    private var inAppJoinButton: some View {
        Button(action: onJoinCall) {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.callout.weight(.semibold))
                Text("JOIN CALL")
                    .font(.brand(.callout, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(UpcomingBookingBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(UpcomingBookingBrand.brandGreen.opacity(isJoinEnabled ? 1.0 : 0.55))
                    .shadow(
                        color: UpcomingBookingBrand.brandGreen.opacity(isJoinEnabled ? 0.45 : 0),
                        radius: 14, x: 0, y: 4
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!isJoinEnabled)
        // Same disabled-state wording as the My Bookings card and Android's
        // shared Join button (`explore_join_call_state`).
        .accessibilityHint(isJoinEnabled ? "" : "Available closer to the session start")
    }

    // MARK: Skype/Zoom variant

    private var openMeetingButton: some View {
        let provider = ExternalMeetingProvider.detect(from: URL(string: joinLink))
        return Button(action: onJoinCall) {
            HStack(spacing: 8) {
                Image(systemName: provider.iconSystemName)
                    .font(.callout.weight(.semibold))
                Text(provider.openButtonTitle)
                    .font(.brand(.callout, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(UpcomingBookingBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(UpcomingBookingBrand.brandGreen.opacity(isJoinEnabled ? 1.0 : 0.55))
                    .shadow(
                        color: UpcomingBookingBrand.brandGreen.opacity(isJoinEnabled ? 0.45 : 0),
                        radius: 14, x: 0, y: 4
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!isJoinEnabled)
        .accessibilityHint(isJoinEnabled ? "" : "Available closer to the session start")
    }

    private var linkRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(UpcomingBookingBrand.videoBg)
                    .frame(width: 42, height: 42)
                Image(systemName: "video")
                    .font(.title3.weight(.regular))
                    .foregroundColor(UpcomingBookingBrand.blueAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Meeting Link")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(UpcomingBookingBrand.onSurface)
                Text(joinLink.isEmpty ? "Not available yet" : joinLink)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button {
                guard !joinLink.isEmpty else { return }
                UIPasteboard.general.string = joinLink
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { didCopyLink = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { didCopyLink = false }
                }
                onCopyLink()
            } label: {
                Image(systemName: didCopyLink ? "checkmark" : "doc.on.doc")
                    .font(.callout.weight(.regular))
                    .foregroundColor(joinLink.isEmpty ? UpcomingBookingBrand.onSurfaceVar : UpcomingBookingBrand.brandGreen)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(joinLink.isEmpty)
            .accessibilityLabel(didCopyLink ? "Link copied" : "Copy meeting link")
        }
    }
}

// MARK: - Previews

#Preview("Teams link") {
    UpcomingBookingJoinCard(
        meetingType: .skypeZoom,
        joinLink: "https://teams.microsoft.com/l/meetup-join/19%3ameeting",
        isJoinEnabled: true,
        onJoinCall: {},
        onCopyLink: {}
    )
    .padding(20)
    .background(UpcomingBookingBrand.bg)
    .preferredColorScheme(.dark)
}

#Preview("Zoom, window closed") {
    UpcomingBookingJoinCard(
        meetingType: .skypeZoom,
        joinLink: "https://zoom.us/j/98237192834",
        isJoinEnabled: false,
        onJoinCall: {},
        onCopyLink: {}
    )
    .padding(20)
    .background(UpcomingBookingBrand.bg)
    .preferredColorScheme(.dark)
}
