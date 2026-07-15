//
//  CancellationBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum CancellationBrand {
    static let bg = Color(red: 0.000, green: 0.000, blue: 0.000)
    static let cardBg = Color(red: 0.075, green: 0.075, blue: 0.075)
    static let cardBorder = Color(red: 0.150, green: 0.165, blue: 0.155)
    static let innerBg = Color(red: 0.110, green: 0.110, blue: 0.110)
    static let innerBorder = Color(red: 0.235, green: 0.290, blue: 0.247)
    static let fieldBg = Color(red: 0.110, green: 0.115, blue: 0.115)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    static let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.600)
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)
    static let errorColor = Color(red: 1.000, green: 0.706, blue: 0.671)
    static let errorBorder = Color(red: 1.000, green: 0.706, blue: 0.671).opacity(0.55)
    static let outlineVar = Color(red: 0.235, green: 0.290, blue: 0.247)
    static let blobPurple = Color(red: 0.48, green: 0.23, blue: 0.93)
}

// MARK: - Button style

struct CancelFlowScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
