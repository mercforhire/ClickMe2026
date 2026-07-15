//
//  BookingConfirmedCheckIcon.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct BookingConfirmedCheckIcon: View {
    let scale: CGFloat
    let opacity: Double
    let glowPulse: Bool

    var body: some View {
        ZStack {
            // Glow behind the circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BookingConfirmedTheme.brandGreen.opacity(glowPulse ? 0.35 : 0.15),
                            BookingConfirmedTheme.brandGreen.opacity(0.0),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 16)
                .animation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                           value: glowPulse)

            // Filled green circle
            Circle()
                .fill(BookingConfirmedTheme.brandGreen)
                .frame(width: 96, height: 96)
                .shadow(color: BookingConfirmedTheme.brandGreen.opacity(0.55), radius: 20, x: 0, y: 4)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(BookingConfirmedTheme.onPrimary)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .frame(height: 160)
    }
}
