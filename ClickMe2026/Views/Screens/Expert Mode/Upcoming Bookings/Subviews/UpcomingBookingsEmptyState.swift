//
//  UpcomingBookingsEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct UpcomingBookingsEmptyState: View {
    var onUpdateAvailability: () -> Void
    var onViewPastHistory: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            calendarEmptyIcon
                .padding(.bottom, 36)

            VStack(spacing: 14) {
                Text("No Upcoming Sessions Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
                    .multilineTextAlignment(.center)

                Text("Once a client books a session with you, it will appear here. In the meantime, ensure your availability is up to date.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Brand.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 36)

            VStack(spacing: 16) {
                Button(action: onUpdateAvailability) {
                    Text("Update Availability")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Brand.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(Brand.primary)
                            .shadow(color: Brand.primary.opacity(0.50), radius: 20, x: 0, y: 6))
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(.horizontal, 40)

                Button(action: onViewPastHistory) {
                    Text("View Past History")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Brand.primary)
                        .underline()
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    /// Canvas-drawn calendar × icon
    private var calendarEmptyIcon: some View {
        Canvas { ctx, size in
            let cx = size.width / 2, cy = size.height / 2, r = size.width / 2

            // Outer faint glow fill
            ctx.fill(
                Path(ellipseIn: CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                with: .color(Brand.primary.opacity(0.06))
            )

            // Dark circle
            let inner = CGRect(x: cx - r * 0.88, y: cy - r * 0.88, width: r * 1.76, height: r * 1.76)
            ctx.fill(Path(ellipseIn: inner), with: .color(Brand.surfaceContainer))
            ctx.stroke(Path(ellipseIn: inner), with: .color(Brand.outlineVariant), lineWidth: 1.5)

            // Calendar outer rounded rect
            let cw: CGFloat = r * 0.80, ch: CGFloat = r * 0.72
            let cx0 = cx - cw / 2, cy0 = cy - ch / 2 + r * 0.04
            let calRect = CGRect(x: cx0, y: cy0, width: cw, height: ch)
            ctx.stroke(Path(roundedRect: calRect, cornerRadius: 8), with: .color(Brand.primary), lineWidth: 2.5)

            // Top header bar
            let barRect = CGRect(x: cx0, y: cy0, width: cw, height: ch * 0.28)
            ctx.fill(Path(roundedRect: barRect, cornerRadius: 8), with: .color(Brand.primary.opacity(0.28)))
            ctx.stroke(Path(roundedRect: barRect, cornerRadius: 8), with: .color(Brand.primary), lineWidth: 2.5)

            // Tab notches
            for dx: CGFloat in [-cw * 0.22, cw * 0.22] {
                let tab = CGRect(x: cx + dx - 4, y: cy0 - ch * 0.13, width: 8, height: ch * 0.17)
                ctx.fill(Path(roundedRect: tab, cornerRadius: 3), with: .color(Brand.primary))
            }

            // × mark
            let xS: CGFloat = r * 0.22, xCy = cy0 + ch * 0.64
            var xPath = Path()
            xPath.move(to: CGPoint(x: cx - xS, y: xCy - xS))
            xPath.addLine(to: CGPoint(x: cx + xS, y: xCy + xS))
            xPath.move(to: CGPoint(x: cx + xS, y: xCy - xS))
            xPath.addLine(to: CGPoint(x: cx - xS, y: xCy + xS))
            ctx.stroke(xPath, with: .color(Brand.primary), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .frame(width: 160, height: 160)
    }
}
