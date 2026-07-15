//
//  ClientProfileAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Read-only avatar with pulsing green ring and ambient glow.

/// Shows the client's public avatar. Read-only — the expert can't change
/// another user's photo; the client owns their own profile picture.
struct ClientProfileAvatar: View {
    let avatarUrl: String?
    let glowPulse: Bool

    var body: some View {
        ZStack {
            ambientGlow
            greenRing
            photo
        }
        .frame(width: 260, height: 200)
    }

    // MARK: Ambient glow

    private var ambientGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        ClientProfileBrand.brandGreen.opacity(glowPulse ? 0.32 : 0.12),
                        ClientProfileBrand.brandGreen.opacity(0.0),
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 130
                )
            )
            .frame(width: 260, height: 260)
            .blur(radius: 16)
            .animation(
                Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                value: glowPulse
            )
    }

    // MARK: Green ring

    private var greenRing: some View {
        Circle()
            .stroke(ClientProfileBrand.brandGreen, lineWidth: 3)
            .frame(width: 148, height: 148)
            .shadow(color: ClientProfileBrand.brandGreen.opacity(0.65), radius: 12, x: 0, y: 0)
    }

    // MARK: Photo

    private var photo: some View {
        Group {
            if let url = avatarUrl.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default: placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 142, height: 142)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        ZStack {
            ClientProfileBrand.avatarFallback
            Image(systemName: "person.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.15))
        }
    }
}
