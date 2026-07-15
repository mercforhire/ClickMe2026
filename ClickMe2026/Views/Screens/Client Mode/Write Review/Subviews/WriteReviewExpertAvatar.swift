//
//  WriteReviewExpertAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Glowing avatar for the expert

struct WriteReviewExpertAvatar: View {
    let imageURL: String
    let glowPulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            WriteReviewBrand.brandGreen.opacity(glowPulse ? 0.32 : 0.12),
                            WriteReviewBrand.brandGreen.opacity(0.0),
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 16)
                .animation(Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                           value: glowPulse)

            Circle()
                .stroke(WriteReviewBrand.brandGreen, lineWidth: 2.5)
                .frame(width: 116, height: 116)
                .shadow(color: WriteReviewBrand.brandGreen.opacity(0.70), radius: 12, x: 0, y: 0)

            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.12, green: 0.18, blue: 0.14)
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(Circle())
        }
        .frame(width: 160, height: 160)
    }
}
