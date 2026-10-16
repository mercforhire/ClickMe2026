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
/// and scheduled time range.
struct SkypeSessionHero: View {
    let peerName: String
    let peerAvatarURL: String
    let topic: String
    let scheduledRangeLabel: String?

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
