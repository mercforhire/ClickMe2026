//
//  MeetingCallAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Pulsing green avatar(s) with ambient glow + connecting ring
//
// While the call is `connecting` or `waitingForPeer`, only the peer's
// avatar is centered — the pulsing ring signals ongoing progress. Once
// both parties are in the channel (`active`), the view swaps to a pair:
// the caller's own avatar on the left, the peer's on the right, both
// framed in the brand-green ring so it's obvious the two are on the
// same call.

struct MeetingCallAvatar: View {
    let expertImageURL: String
    let myAvatarURL: String
    let callStatus: CallStatus
    let glowPulse: Bool
    let ringPulse: Bool

    var body: some View {
        ZStack {
            ambientGlow
            if callStatus == .active {
                pairView
            } else {
                singleView
            }
        }
        .frame(width: 320, height: 260)
        .animation(.easeInOut(duration: 0.35), value: callStatus)
    }

    // MARK: - Single vs. pair layouts

    /// One centered avatar, wrapped in the pulsing connecting ring.
    /// Used while we're still establishing (or waiting on the peer).
    private var singleView: some View {
        ZStack {
            connectingRing
            avatarPhoto(url: expertImageURL, size: 210)
        }
    }

    /// Two avatars side by side — mine on the left, the peer on the
    /// right — connected by a subtle green link so the pair reads as
    /// "these two people are talking to each other."
    private var pairView: some View {
        HStack(spacing: -18) {
            avatarInRing(url: myAvatarURL, size: 130)
            avatarInRing(url: expertImageURL, size: 130)
                .offset(x: 0)
        }
    }

    private func avatarInRing(url: String, size: CGFloat) -> some View {
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
                .frame(width: size + 12, height: size + 12)
            avatarPhoto(url: url, size: size)
        }
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

    private var isPulsing: Bool {
        callStatus == .connecting || callStatus == .waitingForPeer
    }

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
            .scaleEffect(isPulsing ? (ringPulse ? 1.06 : 1.0) : 1.0)
            .animation(
                isPulsing
                    ? Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                    : .default,
                value: ringPulse
            )
    }

    // MARK: Photos

    /// Circular avatar tile. `url` may be empty — falls back to a
    /// person glyph on a dark disc.
    private func avatarPhoto(url: String, size: CGFloat) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case let .success(img):
                img.resizable().scaledToFill()
            default:
                ZStack {
                    MeetingCallBrand.avatarFallback
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.30))
                        .foregroundColor(.white.opacity(0.15))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
