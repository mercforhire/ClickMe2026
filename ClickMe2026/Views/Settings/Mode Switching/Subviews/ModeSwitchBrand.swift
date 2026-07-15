//
//  ModeSwitchBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark (green)

enum ModeSwitchBrand {
    static let brandGreen = Color(red: 0.220, green: 0.878, blue: 0.482) // #38e07b
    static let bgDark = Color(red: 0.071, green: 0.126, blue: 0.090) // #122017
    static let cardActive = Color(red: 0.071, green: 0.126, blue: 0.090)
    static let cardIdle = Color(red: 0.071, green: 0.071, blue: 0.071).opacity(0.85)
    static let borderIdle = Color(red: 0.200, green: 0.200, blue: 0.200)
    static let textPrimary = Color(red: 0.949, green: 0.949, blue: 0.961) // zinc-100
    static let textSub = Color(red: 0.600, green: 0.620, blue: 0.620) // zinc-400
    static let textMuted = Color(red: 0.420, green: 0.430, blue: 0.430) // zinc-500
    static let onPrimary = Color(red: 0.00, green: 0.22, blue: 0.09)
}

// MARK: - Button style

struct ModeScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
