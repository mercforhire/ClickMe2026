//
//  MeetingCallControls.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Mute + Speaker toggle row

struct MeetingCallControls: View {
    let isMuted: Bool
    let isSpeakerOn: Bool
    let onToggleMute: () -> Void
    let onToggleSpeaker: () -> Void

    var body: some View {
        HStack(spacing: 48) {
            MeetingCallControlButton(
                icon: isMuted ? "mic.slash.fill" : "mic.slash",
                label: "Mute",
                isActive: isMuted,
                action: onToggleMute
            )

            MeetingCallControlButton(
                icon: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2",
                label: "Speaker",
                isActive: isSpeakerOn,
                action: onToggleSpeaker
            )
        }
    }
}

// MARK: - Single circular call-control button

struct MeetingCallControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    MeetingCallBrand.controlGradientTop,
                                    MeetingCallBrand.controlGradientBottom,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive
                                        ? MeetingCallBrand.brandGreen.opacity(0.50)
                                        : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                        .frame(width: 76, height: 76)
                        .shadow(color: Color.black.opacity(0.40), radius: 12, x: 0, y: 6)

                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(isActive ? MeetingCallBrand.brandGreen : MeetingCallBrand.onSurface)
                }
            }
            .buttonStyle(CallControlStyle())

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(MeetingCallBrand.onSurfaceVar)
        }
    }
}
