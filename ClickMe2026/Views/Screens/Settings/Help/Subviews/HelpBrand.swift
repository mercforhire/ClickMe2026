//
//  HelpBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum HelpBrand {
    static let bg = Color(red: 0.075, green: 0.080, blue: 0.095)
    static let cardBg = Color(red: 0.095, green: 0.100, blue: 0.118)
    static let fieldBg = Color(red: 0.108, green: 0.125, blue: 0.140)
    static let brandGreen = Brand.primary
    static let onSurface = Brand.onSurface
    static let onSurfaceVar = Color(red: 0.730, green: 0.795, blue: 0.738)

    /// Iridescent card border: purple → blue → green
    static let iridBorder = LinearGradient(
        colors: [
            Color(red: 0.52, green: 0.40, blue: 0.88).opacity(0.65),
            Color(red: 0.35, green: 0.52, blue: 0.88).opacity(0.50),
            Color(red: 0.20, green: 0.78, blue: 0.60).opacity(0.40),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Section header

struct HelpSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundColor(HelpBrand.onSurface)
            .fixedSize(horizontal: false, vertical: true)
    }
}
