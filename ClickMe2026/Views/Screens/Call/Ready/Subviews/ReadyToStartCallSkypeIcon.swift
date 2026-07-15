//
//  ReadyToStartCallSkypeIcon.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Skype-inspired glass icon with pulsing green ambient glow

struct ReadyToStartCallSkypeIcon: View {
    let scale: CGFloat
    let opacity: Double
    let glowPulse: Bool

    var body: some View {
        ZStack {
            ambientGlow
            glassIcon
        }
        .scaleEffect(scale)
        .opacity(opacity)
    }

    // MARK: Glow

    private var ambientGlow: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(RadialGradient(
                colors: [
                    ReadyToStartCallBrand.brandGreen.opacity(glowPulse ? 0.22 : 0.08),
                    .clear,
                ],
                center: .center, startRadius: 0, endRadius: 70
            ))
            .frame(width: 140, height: 140)
            .blur(radius: 18)
            .animation(
                Animation.easeInOut(duration: 2.3).repeatForever(autoreverses: true),
                value: glowPulse
            )
    }

    // MARK: Glass container + Skype "S"

    private var glassIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            ReadyToStartCallBrand.iconGradientTop,
                            ReadyToStartCallBrand.iconGradientBottom,
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .frame(width: 88, height: 88)
                .shadow(color: ReadyToStartCallBrand.brandGreen.opacity(0.20), radius: 16, x: 0, y: 4)

            // Skype "S" drawn as two offset arcs
            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let r: CGFloat = 22

                var path = Path()
                path.addArc(
                    center: CGPoint(x: cx + 2, y: cy - 8),
                    radius: r, startAngle: .degrees(160), endAngle: .degrees(20),
                    clockwise: false
                )
                path.addArc(
                    center: CGPoint(x: cx - 2, y: cy + 8),
                    radius: r, startAngle: .degrees(-20), endAngle: .degrees(200),
                    clockwise: false
                )
                ctx.stroke(
                    path,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(width: 56, height: 56)
        }
    }
}
