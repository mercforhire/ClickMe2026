//
//  ReadyToStartCallBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum ReadyToStartCallBrand {
    static let bg = Color(red: 0.075, green: 0.075, blue: 0.085) // #131318
    static let cardBg = Color(red: 0.100, green: 0.105, blue: 0.120)
    static let cardBorder = Color(red: 0.220, green: 0.235, blue: 0.270)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592) // #44f697
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882) // #e5e2e1
    static let onSurfaceVar = Color(red: 0.600, green: 0.640, blue: 0.630)
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114) // #003920
    static let outlineVar = Color(red: 0.235, green: 0.290, blue: 0.247)

    // Blob colours (teal / purple / blue) matching screenshot
    static let blobTeal = Color(red: 0.30, green: 0.75, blue: 0.70)
    static let blobPurple = Color(red: 0.50, green: 0.35, blue: 0.85)
    static let blobBlue = Color(red: 0.25, green: 0.45, blue: 0.90)

    // Skype icon container gradient stops
    static let iconGradientTop = Color(red: 0.22, green: 0.26, blue: 0.34)
    static let iconGradientBottom = Color(red: 0.14, green: 0.17, blue: 0.22)
}

// MARK: - Button style

struct SkypeScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
