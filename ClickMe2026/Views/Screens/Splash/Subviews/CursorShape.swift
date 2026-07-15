//
//  CursorShape.swift
//  ClickMe
//

import SwiftUI

/// A classic pointer/cursor, drawn pointing down-and-right.
struct CursorShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 100 * w, y: rect.minY + y / 100 * h)
        }

        var path = Path()
        // Arrow pointing toward the bottom-right corner.
        path.move(to: p(100, 100)) // tip
        path.addLine(to: p(30, 88))
        path.addLine(to: p(45, 68))
        path.addLine(to: p(18, 56))
        path.addLine(to: p(23, 44))
        path.addLine(to: p(50, 56))
        path.addLine(to: p(56, 30))
        path.closeSubpath()
        return path
    }
}
