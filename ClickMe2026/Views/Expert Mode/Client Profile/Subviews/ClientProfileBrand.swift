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
    static let bg = Color(red: 0.075, green: 0.075, blue: 0.075) // #131313
    static let bgGradientTop = Color(red: 0.06, green: 0.13, blue: 0.08) // subtle green cast
    static let surface = Color(red: 0.075, green: 0.110, blue: 0.085) // card bg with green tint
    static let outlineVar = Color(red: 0.235, green: 0.290, blue: 0.247) // #3c4a3f
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592) // #44f697
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882) // #e5e2e1
    static let onSurfaceVar = Color(red: 0.729, green: 0.796, blue: 0.737) // #bacbbc
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114) // #003920
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
