//
//  MeetingCallControls.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Minimize + Chat + Mute + Speaker toggle row

struct MeetingCallControls: View {
    let isMuted: Bool
    let isSpeakerOn: Bool
    /// Shrinks the expanded call surface into the floating pill, letting
    /// the user browse the app while audio keeps running. Moved into
    /// this bottom control row (from the old top-left position) because
    /// SwiftUI's safe-area propagation on top of `fullScreenCover` was
    /// unreliable — the chevron kept ending up underneath the notch.
    let onMinimize: () -> Void
    /// Tap minimizes the call and hands off to the Chats tab with the
    /// peer's thread pushed. `CallCenter.requestOpenChatWithPeer()`
    /// handles the minimize-then-navigate flow.
    let onOpenChat: () -> Void
    let onToggleMute: () -> Void
    let onToggleSpeaker: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            MeetingCallControlButton(
                icon: "chevron.compact.down",
                label: "Minimize",
                isActive: false,
                action: onMinimize
            )

            MeetingCallControlButton(
                icon: "bubble.left.and.bubble.right.fill",
                label: "Chat",
                isActive: false,
                action: onOpenChat
            )

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
    /// When true, swaps the icon for a small spinner and disables the
    /// tap. Used by the Chat button while `initiateChat` is resolving.
    var isBusy: Bool = false
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

                    if isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(MeetingCallBrand.onSurface)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 26, weight: .regular))
                            .foregroundColor(isActive ? MeetingCallBrand.brandGreen : MeetingCallBrand.onSurface)
                    }
                }
            }
            .buttonStyle(CallControlStyle())
            .disabled(isBusy)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(MeetingCallBrand.onSurfaceVar)
        }
    }
}
