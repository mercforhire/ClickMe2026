//
//  RescheduleBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum RescheduleBrand {
    static let bg = Color(red: 0.075, green: 0.080, blue: 0.095) // #131318
    static let cardBg = Color(red: 0.108, green: 0.118, blue: 0.130) // glass dark
    static let cardBorder = Color(red: 0.170, green: 0.185, blue: 0.200)
    static let chipBg = Color(red: 0.130, green: 0.140, blue: 0.158)
    static let chipBorder = Color(red: 0.200, green: 0.215, blue: 0.230)
    static let brandGreen = Brand.primary // #44f697
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Color(red: 0.620, green: 0.660, blue: 0.640)
    static let onPrimary = Brand.onPrimary // #003920
    static let avatarFallback = Color(red: 0.10, green: 0.16, blue: 0.12)
}

// MARK: - Shared card background

struct RescheduleCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(RescheduleBrand.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(RescheduleBrand.cardBorder, lineWidth: 1)
            )
    }
}
