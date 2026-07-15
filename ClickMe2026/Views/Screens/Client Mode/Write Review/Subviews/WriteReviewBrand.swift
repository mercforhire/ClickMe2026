//
//  WriteReviewBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum WriteReviewBrand {
    static let bg = Color(red: 0.075, green: 0.075, blue: 0.075) // #131313
    static let surfaceContainer = Color(red: 0.125, green: 0.125, blue: 0.125)
    static let surfaceHigh = Color(red: 0.165, green: 0.165, blue: 0.165)
    static let outlineVariant = Color(red: 0.235, green: 0.290, blue: 0.247)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592) // #44f697
    static let brandGreenAlt = Color(red: 0.13, green: 0.85, blue: 0.53)
    static let brandGreenAlt2 = Color(red: 0.18, green: 0.85, blue: 0.52)
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    static let onSurfaceVar = Color(red: 0.729, green: 0.796, blue: 0.737)
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)
    static let fieldBg = Color(red: 0.090, green: 0.110, blue: 0.095)
    static let fieldBorder = Color(red: 0.235, green: 0.290, blue: 0.247)
    static let topTint = Color(red: 0.06, green: 0.11, blue: 0.07)
}

// MARK: - Button styles

struct StarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.20, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

struct ReviewSubmitStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
