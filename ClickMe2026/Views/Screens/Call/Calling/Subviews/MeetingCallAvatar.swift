//
//  MeetingCallAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Pulsing green avatar with ambient glow + connecting ring

struct MeetingCallAvatar: View {
    let expertImageURL: String
    let callStatus: CallStatus
    let glowPulse: Bool
    let ringPulse: Bool

    var body: some View {
        ZStack {
            ambientGlow
            connectingRing
            expertPhoto
        }
        .frame(width: 260, height: 260)
    }

    // MARK: Ambient glow

    private var ambientGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        MeetingCallBrand.brandGreen.opacity(glowPulse ? 0.28 : 0.10),
                        MeetingCallBrand.brandGreen.opacity(0.0),
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 200
                )
            )
            .frame(width: 360, height: 360)
            .blur(radius: 20)
            .animation(
                Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                value: glowPulse
            )
    }

    // MARK: Connecting ring

    private var connectingRing: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        MeetingCallBrand.brandGreen,
                        MeetingCallBrand.brandGreen.opacity(0.50),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .frame(width: 220, height: 220)
            .shadow(color: MeetingCallBrand.brandGreen.opacity(0.60), radius: 14, x: 0, y: 0)
            .scaleEffect(callStatus == .connecting ? (ringPulse ? 1.06 : 1.0) : 1.0)
            .animation(
                callStatus == .connecting
                    ? Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                    : .default,
                value: ringPulse
            )
    }

    // MARK: Expert photo

    private var expertPhoto: some View {
        AsyncImage(url: URL(string: expertImageURL)) { phase in
            switch phase {
            case let .success(img):
                img.resizable().scaledToFill()
            default:
                ZStack {
                    MeetingCallBrand.avatarFallback
                    Image(systemName: "person.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.15))
                }
            }
        }
        .frame(width: 210, height: 210)
        .clipShape(Circle())
    }
}
