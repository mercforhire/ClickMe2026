//
//  ProfileSettingsBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum ProfileSettingsBrand {
    static let bg = Color(red: 0.035, green: 0.065, blue: 0.045)
    static let fieldBg = Color(red: 0.065, green: 0.110, blue: 0.075)
    static let fieldBorder = Color(red: 0.200, green: 0.340, blue: 0.230)
    static let chipBg = Color(red: 0.100, green: 0.160, blue: 0.115)
    static let chipBorder = Color(red: 0.220, green: 0.360, blue: 0.245)
    static let settingsBg = Color(red: 0.060, green: 0.090, blue: 0.065)
    static let settingsBdr = Color(red: 0.180, green: 0.280, blue: 0.200)
    static let brandGreen = Brand.primary
    static let onSurface = Brand.onSurface
    static let onSurfaceVar = Brand.onSurfaceVariant
    static let onPrimary = Brand.onPrimary
    static let labelColor = Brand.primary
    static let sheetBg = Color(red: 0.055, green: 0.090, blue: 0.065)
}

// MARK: - Flow layout

struct ProfileFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        var h: CGFloat = 0; var x: CGFloat = 0; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > w, x > 0 { h += rowH + spacing; x = 0; rowH = 0 }
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: w, height: h + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}
