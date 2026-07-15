//
//  ChattingGlowingBubbles.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Empty-state Canvas illustration

struct ChattingGlowingBubbles: View {
    var body: some View {
        ZStack {
            // Green blob behind
            Ellipse()
                .fill(RadialGradient(
                    colors: [ChattingBrand.brandGreen.opacity(0.35), .clear],
                    center: .center, startRadius: 0, endRadius: 130
                ))
                .frame(width: 300, height: 240)
                .blur(radius: 36)

            // Teal blob top-right
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.35, green: 0.80, blue: 0.70).opacity(0.28), .clear],
                    center: .center, startRadius: 0, endRadius: 110
                ))
                .frame(width: 220, height: 200)
                .blur(radius: 28)
                .offset(x: 60, y: -40)

            // Two chat bubble shapes drawn with Canvas
            Canvas { ctx, size in
                let green = Color(red: 0.267, green: 0.965, blue: 0.592)
                let greenGlow = green.opacity(0.25)
                let cx = size.width / 2
                let cy = size.height / 2

                // ── Back bubble (right) ──
                let b2 = CGRect(x: cx - 10, y: cy - 30, width: 130, height: 100)
                let p2 = Self.roundedBubblePath(rect: b2, cornerRadius: 20, tailLeft: false)
                ctx.fill(p2, with: .color(green.opacity(0.55)))
                var glow2 = ctx; glow2.addFilter(.blur(radius: 8))
                glow2.stroke(p2, with: .color(greenGlow), lineWidth: 6)
                ctx.stroke(p2, with: .color(green.opacity(0.80)), lineWidth: 1.5)

                // Slash line over back bubble
                var slash = Path()
                slash.move(to: CGPoint(x: cx + 60, y: cy - 50))
                slash.addLine(to: CGPoint(x: cx - 10, y: cy + 70))
                ctx.stroke(slash, with: .color(green.opacity(0.55)),
                           style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

                // ── Front bubble (left) ──
                let b1 = CGRect(x: cx - 130, y: cy - 60, width: 140, height: 108)
                let p1 = Self.roundedBubblePath(rect: b1, cornerRadius: 22, tailLeft: true)
                ctx.fill(p1, with: .color(green.opacity(0.65)))
                var glow1 = ctx; glow1.addFilter(.blur(radius: 10))
                glow1.stroke(p1, with: .color(greenGlow), lineWidth: 8)
                ctx.stroke(p1, with: .color(green), lineWidth: 2)

                // Slash line over front bubble
                var slash2 = Path()
                slash2.move(to: CGPoint(x: cx - 100, y: cy - 70))
                slash2.addLine(to: CGPoint(x: cx + 20, y: cy + 60))
                ctx.stroke(slash2, with: .color(green.opacity(0.45)),
                           style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
            .frame(width: 300, height: 220)
        }
        .frame(width: 300, height: 260)
    }

    /// Rounded-rectangle chat bubble with a small tail
    private static func roundedBubblePath(rect: CGRect, cornerRadius: CGFloat, tailLeft: Bool) -> Path {
        var p = Path()
        let r = cornerRadius
        let tailW: CGFloat = 14
        let tailH: CGFloat = 16
        let tailX: CGFloat = tailLeft ? rect.minX + 20 : rect.maxX - 20 - tailW

        p.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))

        var tail = Path()
        tail.move(to: CGPoint(x: tailX, y: rect.maxY))
        tail.addLine(to: CGPoint(x: tailX + tailW / 2, y: rect.maxY + tailH))
        tail.addLine(to: CGPoint(x: tailX + tailW, y: rect.maxY))
        tail.closeSubpath()
        p.addPath(tail)

        return p
    }
}
