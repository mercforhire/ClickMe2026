//
//  ClientProfileBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark (green)

enum ClientProfileBrand {
    static let bg = Brand.surface // #131313
    static let bgGradientTop = Color(red: 0.06, green: 0.13, blue: 0.08) // subtle green cast
    static let surface = Color(red: 0.075, green: 0.110, blue: 0.085) // card bg with green tint
    static let outlineVar = Brand.outlineVariant // #3c4a3f
    static let brandGreen = Brand.primary
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Brand.onSurfaceVariant // #bacbbc
    static let onPrimary = Brand.onPrimary // #003920
    static let fieldBg = Color(red: 0.065, green: 0.110, blue: 0.075)
    static let fieldBorder = Color(red: 0.200, green: 0.280, blue: 0.220)
    static let chipBg = Color(red: 0.140, green: 0.190, blue: 0.155)
    static let avatarFallback = Color(red: 0.12, green: 0.18, blue: 0.14)
}

// MARK: - Top-radial green tint background

struct ClientProfileBackground: View {
    var body: some View {
        LinearGradient(
            colors: [ClientProfileBrand.bgGradientTop, ClientProfileBrand.bg],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.45)
        )
        .ignoresSafeArea()
    }
}
