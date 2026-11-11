//
//  SkypeSessionHero.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Compact peer / topic hero for the Skype/Zoom external-meeting
/// variant of the call screen. Single avatar (no dual-avatar treatment
/// since there's no live audio to visually anchor), peer name, topic,
/// scheduled time range, and the session timer.
struct SkypeSessionHero: View {
    let peerName: String
    let peerAvatarURL: String
    let topic: String
    let scheduledRangeLabel: String?
    /// Same values the in-app voice layout feeds `MeetingCallInfo` (CALL-07, D-08).
    let timerString: String
    let remainingLabel: String?
    let isNearOrPastEnd: Bool

    var body: some View {
        VStack(spacing: 14) {
            avatar
                .padding(.bottom, 8)

            Text(peerName)
                .font(.brand(.title, weight: .bold))
                .foregroundColor(MeetingCallBrand.onSurface)
                .multilineTextAlignment(.center)

            if !topic.isEmpty {
                Text(topic)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(MeetingCallBrand.onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let scheduledRangeLabel {
                Text(scheduledRangeLabel)
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(MeetingCallBrand.onSurfaceVar.opacity(0.75))
            }

            Text(timerString)
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(isNearOrPastEnd ? .orange : MeetingCallBrand.onSurfaceVar)
                .padding(.top, 4)

            if let remainingLabel {
                Text(remainingLabel)
                    .font(.brand(.caption, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                            .overlay(Capsule().stroke(Color.orange.opacity(0.45), lineWidth: 1))
                    )
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            MeetingCallBrand.brandGreen,
                            MeetingCallBrand.brandGreen.opacity(0.55),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .shadow(color: MeetingCallBrand.brandGreen.opacity(0.50), radius: 10)
                .frame(width: 152, height: 152)

            AsyncImage(url: URL(string: peerAvatarURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        MeetingCallBrand.avatarFallback
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(Circle())
        }
    }
}

#Preview("Near the end") {
    ZStack {
        MeetingCallBackground()
        SkypeSessionHero(
            peerName: "Sophia Carter",
            peerAvatarURL: "",
            topic: "Advanced Product Strategy Review",
            scheduledRangeLabel: "10:30 AM – 11:00 AM",
            timerString: "25:12",
            remainingLabel: "4:48 left",
            isNearOrPastEnd: true
        )
    }
    .preferredColorScheme(.dark)
}
