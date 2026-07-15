//
//  EnvelopeGlowBubble.swift
//  ClickMe2026
//

import SwiftUI

/// Glowing dark-glass sphere with a centered envelope icon. The outer halo
/// pulses on/off based on the `glowPulse` flag.
struct EnvelopeGlowBubble: View {
    let glowPulse: Bool

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            VerifyEmailBrand.green.opacity(glowPulse ? 0.38 : 0.20),
                            VerifyEmailBrand.green.opacity(0.06),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 90
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 12)
                .animation(
                    Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: glowPulse
                )

            // Dark glass sphere
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.22, blue: 0.24),
                            Color(red: 0.10, green: 0.12, blue: 0.14),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.04),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .frame(width: 130, height: 130)
                .shadow(color: VerifyEmailBrand.green.opacity(0.25), radius: 20, x: 0, y: 4)

            // Envelope icon
            Image(systemName: "envelope.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.92, blue: 0.90),
                            Color(red: 0.65, green: 0.75, blue: 0.70),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: VerifyEmailBrand.green.opacity(0.40), radius: 8, x: 0, y: 2)
        }
    }
}
