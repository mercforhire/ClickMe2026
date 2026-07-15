//
//  ReportChatBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum ReportChatBrand {
    static let bg = Brand.surface // #131313
    static let cardBg = Color(red: 0.090, green: 0.100, blue: 0.100) // #171a1a
    static let fieldBg = Color(red: 0.120, green: 0.130, blue: 0.135) // #1f2122
    static let fieldBorder = Color(red: 0.220, green: 0.240, blue: 0.230) // charcoal
    static let brandGreen = Brand.primary // #44f697
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Color(red: 0.600, green: 0.640, blue: 0.630) // muted
    static let onPrimary = Brand.onPrimary // #003920
    static let errorRed = Color(red: 1.000, green: 0.380, blue: 0.360) // #ff614d
    static let errorBorder = Color(red: 1.000, green: 0.380, blue: 0.360).opacity(0.55)

    /// Iridescent purple → blue → green card border.
    static let cardBorder = LinearGradient(
        colors: [
            Color(red: 0.55, green: 0.40, blue: 0.90).opacity(0.65),
            Color(red: 0.40, green: 0.55, blue: 0.90).opacity(0.45),
            Color(red: 0.30, green: 0.80, blue: 0.65).opacity(0.35),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Iridescent glass card background

struct ReportChatGlassCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(ReportChatBrand.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(ReportChatBrand.cardBorder, lineWidth: 1.5)
            )
    }
}
