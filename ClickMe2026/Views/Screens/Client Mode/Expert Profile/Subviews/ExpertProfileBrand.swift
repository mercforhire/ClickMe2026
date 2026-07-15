//
//  ExpertProfileBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum ExpertProfileBrand {
    static let bg = Brand.surface
    static let surfaceContainer = Color(red: 0.125, green: 0.125, blue: 0.125)
    static let surfaceHigh = Brand.surfaceContainerHigh
    static let outlineVar = Brand.outlineVariant
    static let brandGreen = Brand.primary
    static let onSurface = Brand.onSurface
    static let onSurfaceVar = Brand.onSurfaceVariant
    static let onPrimary = Brand.onPrimary
    static let starYellow = Brand.primary // green stars per design
    static let tagBg = Color(red: 0.140, green: 0.165, blue: 0.145)
    static let cardBg = Color(red: 0.100, green: 0.120, blue: 0.105)
    static let cardBorder = Color(red: 0.180, green: 0.230, blue: 0.190)
    static let topicsHeaderBg = Color(red: 0.085, green: 0.105, blue: 0.090)
}

// MARK: - Button style

struct ProfileActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Tag flow layout

struct ExpertFlowLayoutView: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        var h: CGFloat = 0; var rowX: CGFloat = 0; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if rowX + s.width > w, rowX > 0 { h += rowH + spacing; rowX = 0; rowH = 0 }
            rowX += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: w, height: h + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowX = bounds.minX; var rowY = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if rowX + s.width > bounds.maxX, rowX > bounds.minX { rowY += rowH + spacing; rowX = bounds.minX; rowH = 0 }
            v.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(s))
            rowX += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}
