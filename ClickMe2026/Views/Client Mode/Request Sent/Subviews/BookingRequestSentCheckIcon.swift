//
//  BookingRequestSentCheckIcon.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Animated green check icon with pulsing outer glow

struct BookingRequestSentCheckIcon: View {
    let scale: CGFloat
    let opacity: Double
    let glowPulse: Bool

    var body: some View {
        ZStack {
            // Pulsing outer glow
            Circle()
                .fill(RadialGradient(
                    colors: [
                        BookingRequestSentBrand.brandGreen.opacity(glowPulse ? 0.38 : 0.12),
                        .clear,
                    ],
                    center: .center, startRadius: 0, endRadius: 100
                ))
                .frame(width: 210, height: 210)
                .blur(radius: 20)
                .animation(
                    Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: glowPulse
                )

            // Dark circle background
            Circle()
                .fill(BookingRequestSentBrand.checkBg)
                .overlay(Circle().stroke(BookingRequestSentBrand.brandGreen.opacity(0.25), lineWidth: 1))
                .frame(width: 128, height: 128)

            // Check circle icon
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(BookingRequestSentBrand.brandGreen)
                .shadow(color: BookingRequestSentBrand.brandGreen.opacity(0.70), radius: 12)
        }
        .scaleEffect(scale)
        .opacity(opacity)
    }
}
