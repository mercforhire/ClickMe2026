//
//  HeartKnotShape.swift
//  ClickMe
//

import SwiftUI

/// A heart outline with a small crossing "twist" to hint at the woven knot.
struct HeartKnotShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 100 * w, y: rect.minY + y / 100 * h)
        }

        var path = Path()

        // Heart outline (starts at the top-center dip, runs clockwise).
        path.move(to: p(50, 30))
        path.addCurve(to: p(10, 22),  control1: p(43, 13), control2: p(20, 11))   // left lobe top
        path.addCurve(to: p(50, 86),  control1: p(-4, 36), control2: p(26, 62))   // left side to tip
        path.addCurve(to: p(90, 22),  control1: p(74, 62), control2: p(104, 36))  // right side up
        path.addCurve(to: p(50, 30),  control1: p(80, 11), control2: p(57, 13))   // right lobe to dip

        // Knot "twist": a short over-strap across the top-center dip.
        path.move(to: p(41, 24))
        path.addCurve(to: p(59, 24), control1: p(47, 34), control2: p(53, 34))

        return path
    }
}
