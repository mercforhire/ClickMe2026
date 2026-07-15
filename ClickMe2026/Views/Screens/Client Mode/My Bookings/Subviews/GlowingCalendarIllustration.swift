//
//  GlowingCalendarIllustration.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Canvas-drawn glowing calendar (empty-state illustration)

struct GlowingCalendarIllustration: View {
    let glowPulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [MyBookingsBrand.brandGreen.opacity(glowPulse ? 0.35 : 0.14), .clear],
                    center: .center, startRadius: 0, endRadius: 130
                ))
                .frame(width: 280, height: 280)
                .blur(radius: 22)
                .animation(Animation.easeInOut(duration: 2.3).repeatForever(autoreverses: true),
                           value: glowPulse)

            Canvas { ctx, size in
                let cw = size.width, ch = size.height
                let green = MyBookingsBrand.brandGreen
                let darkCard = Color(red: 0.11, green: 0.14, blue: 0.12)

                let cal = CGRect(x: cw * 0.12, y: ch * 0.08, width: cw * 0.62, height: ch * 0.74)
                let calPath = Path(roundedRect: cal, cornerRadius: 14)
                ctx.fill(calPath, with: .color(darkCard))
                ctx.stroke(calPath, with: .color(green), lineWidth: 2.5)

                for x in [cal.minX + 18, cal.maxX - 18] {
                    let ring = Path(ellipseIn: CGRect(x: x - 7, y: cal.minY - 12, width: 14, height: 20))
                    ctx.fill(ring, with: .color(green))
                }

                let header = CGRect(x: cal.minX, y: cal.minY, width: cal.width, height: cal.height * 0.22)
                let headerPath = Path(roundedRect: header, cornerRadius: 14, style: .continuous)
                ctx.fill(headerPath, with: .color(green.opacity(0.85)))

                let cols = 3; let rows = 3
                let padX: CGFloat = 18
                let innerY = cal.minY + cal.height * 0.28
                let innerH = cal.height * 0.60
                let innerX = cal.minX + padX
                let innerW = cal.width - padX * 2
                let cellW = innerW / CGFloat(cols)
                let cellH = innerH / CGFloat(rows)

                for r in 0 ..< rows {
                    for c in 0 ..< cols {
                        let cx = innerX + CGFloat(c) * cellW + cellW / 2
                        let cy = innerY + CGFloat(r) * cellH + cellH / 2
                        let dot = Path(roundedRect: CGRect(x: cx - 7, y: cy - 5, width: 14, height: 10), cornerRadius: 3)
                        ctx.fill(dot, with: .color(green.opacity(0.80)))
                    }
                }

                let clkCX = cw * 0.76
                let clkCY = ch * 0.74
                let clkR: CGFloat = 28
                let clkBg = Path(ellipseIn: CGRect(x: clkCX - clkR - 2, y: clkCY - clkR - 2,
                                                   width: (clkR + 2) * 2, height: (clkR + 2) * 2))
                ctx.fill(clkBg, with: .color(darkCard))

                let clkRing = Path(ellipseIn: CGRect(x: clkCX - clkR, y: clkCY - clkR,
                                                     width: clkR * 2, height: clkR * 2))
                ctx.fill(clkRing, with: .color(green.opacity(0.25)))
                ctx.stroke(clkRing, with: .color(green), lineWidth: 2.5)

                func line(from: CGPoint, to: CGPoint) {
                    var p = Path(); p.move(to: from); p.addLine(to: to)
                    ctx.stroke(p, with: .color(green), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                line(from: CGPoint(x: clkCX, y: clkCY),
                     to: CGPoint(x: clkCX, y: clkCY - clkR * 0.58))
                line(from: CGPoint(x: clkCX, y: clkCY),
                     to: CGPoint(x: clkCX + clkR * 0.55, y: clkCY))
            }
            .frame(width: 180, height: 180)
        }
        .frame(width: 240, height: 240)
    }
}
