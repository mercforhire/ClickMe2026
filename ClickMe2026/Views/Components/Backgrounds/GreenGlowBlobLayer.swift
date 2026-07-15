//
//  GreenGlowBlobLayer.swift
//  ClickMe2026
//
//  Two soft-glowing brand-green ellipses positioned at the top-right and
//  mid-left of the container. Intended as a background layer behind the
//  main screen surface.
//

import SwiftUI

struct GreenGlowBlobLayer: View {
    private let opacity: Double = 0.18
    private let blur: CGFloat = 44
    private let radius: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            ZStack {
                blob(x: geo.size.width + 30, y: geo.size.height * 0.10)
                blob(x: -20, y: geo.size.height * 0.65)
            }
        }
    }

    private func blob(x: CGFloat, y: CGFloat) -> some View {
        Ellipse()
            .fill(RadialGradient(
                colors: [Brand.primary.opacity(opacity), .clear],
                center: .center,
                startRadius: 0,
                endRadius: radius / 2
            ))
            .frame(width: radius, height: radius)
            .blur(radius: blur)
            .position(x: x, y: y)
    }
}
