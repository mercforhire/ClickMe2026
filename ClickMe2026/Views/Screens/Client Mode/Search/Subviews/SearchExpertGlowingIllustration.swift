//
//  SearchExpertGlowingIllustration.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Canvas-drawn magnifier + network illustration (empty state)

struct SearchExpertGlowingIllustration: View {
    let glowPulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [SearchExpertBrand.brandGreen.opacity(glowPulse ? 0.30 : 0.10), .clear],
                    center: .center, startRadius: 0, endRadius: 140
                ))
                .frame(width: 300, height: 300)
                .blur(radius: 24)
                .animation(Animation.easeInOut(duration: 2.3).repeatForever(autoreverses: true),
                           value: glowPulse)

            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let green = Brand.primary
                let strokeStyle = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)

                func glowStroke(_ path: Path, width: CGFloat = 2.5) {
                    var blurCtx = ctx
                    blurCtx.addFilter(.blur(radius: 6))
                    blurCtx.stroke(path, with: .color(green.opacity(0.55)),
                                   style: StrokeStyle(lineWidth: width + 4, lineCap: .round))
                    ctx.stroke(path, with: .color(green), style: strokeStyle)
                }

                // ── Magnifying glass ──
                let lensR: CGFloat = 52
                let lensCX = cx - 10
                let lensCY = cy - 8
                var lens = Path()
                lens.addEllipse(in: CGRect(x: lensCX - lensR, y: lensCY - lensR,
                                           width: lensR * 2, height: lensR * 2))
                glowStroke(lens)

                // Handle
                var handle = Path()
                handle.move(to: CGPoint(x: lensCX + lensR * 0.707, y: lensCY + lensR * 0.707))
                handle.addLine(to: CGPoint(x: lensCX + lensR * 0.707 + 30,
                                           y: lensCY + lensR * 0.707 + 30))
                glowStroke(handle)

                // Inner graph lines inside the lens
                let pts: [(CGFloat, CGFloat)] = [(-28, -6), (-8, 10), (14, -14), (30, 6)]
                var graph = Path()
                for (i, pt) in pts.enumerated() {
                    let p = CGPoint(x: lensCX + pt.0, y: lensCY + pt.1)
                    if i == 0 { graph.move(to: p) } else { graph.addLine(to: p) }
                }
                ctx.stroke(graph, with: .color(green.opacity(0.80)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                for pt in pts {
                    let dot = CGRect(x: lensCX + pt.0 - 3, y: lensCY + pt.1 - 3, width: 6, height: 6)
                    ctx.fill(Path(ellipseIn: dot), with: .color(green))
                }

                // ── Network nodes around the lens ──
                let nodes: [(CGFloat, CGFloat, CGFloat)] = [
                    (-80, -60, 5),
                    (30, -85, 4),
                    (95, -30, 4),
                    (-95, 30, 3),
                    (0, 90, 3),
                ]
                let hubPts: [(CGFloat, CGFloat)] = nodes.map { (cx + $0.0, cy + $0.1) }
                for (i, n) in nodes.enumerated() {
                    let pt = CGPoint(x: cx + n.0, y: cy + n.1)
                    let angle = atan2(pt.y - lensCY, pt.x - lensCX)
                    let edgePt = CGPoint(x: lensCX + cos(angle) * lensR,
                                         y: lensCY + sin(angle) * lensR)
                    var line = Path(); line.move(to: pt); line.addLine(to: edgePt)
                    ctx.stroke(line, with: .color(green.opacity(0.45)),
                               style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x - n.2, y: pt.y - n.2,
                                                    width: n.2 * 2, height: n.2 * 2)),
                             with: .color(green))

                    if i < nodes.count - 1 {
                        let next = hubPts[i + 1]
                        var conn = Path(); conn.move(to: pt); conn.addLine(to: CGPoint(x: next.0, y: next.1))
                        ctx.stroke(conn, with: .color(green.opacity(0.25)),
                                   style: StrokeStyle(lineWidth: 1, lineCap: .round))
                    }
                }

                // Small scatter dots
                let scatterDots: [(CGFloat, CGFloat)] = [
                    (-55, -90), (60, -65), (110, 20), (50, 100), (-30, 110),
                ]
                for dot in scatterDots {
                    let r: CGFloat = 2
                    ctx.fill(Path(ellipseIn: CGRect(x: cx + dot.0 - r, y: cy + dot.1 - r,
                                                    width: r * 2, height: r * 2)),
                             with: .color(green.opacity(0.60)))
                }
            }
            .frame(width: 280, height: 260)
        }
        .frame(width: 280, height: 280)
    }
}
