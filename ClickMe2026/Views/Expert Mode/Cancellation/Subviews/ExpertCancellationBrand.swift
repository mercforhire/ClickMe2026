//
//  ExpertCancellationBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark (green)

enum ExpertCancellationBrand {
    static let bg = Color(red: 0.040, green: 0.065, blue: 0.048) // dark green-black
    static let cardBg = Color(red: 0.072, green: 0.108, blue: 0.082) // glass panel green
    static let cardBorder = Color(red: 0.145, green: 0.235, blue: 0.170)
    static let innerBg = Color(red: 0.095, green: 0.135, blue: 0.105) // client info bg
    static let innerBorder = Color(red: 0.155, green: 0.250, blue: 0.182)
    static let dropdownBg = Color(red: 0.085, green: 0.120, blue: 0.092)
    static let iconCircle = Color(red: 0.082, green: 0.118, blue: 0.090)
    static let iconBorder = Color(red: 0.155, green: 0.250, blue: 0.182)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    static let onSurfaceVar = Color(red: 0.580, green: 0.660, blue: 0.615)
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)
    static let errorColor = Color(red: 1.000, green: 0.706, blue: 0.671) // #ffb4ab
    static let errorBorder = Color(red: 1.000, green: 0.706, blue: 0.671).opacity(0.50)
    static let avatarFallback = Color(red: 0.10, green: 0.16, blue: 0.12)
    static let reasonSheetBg = Color(red: 0.055, green: 0.090, blue: 0.065)
}

// MARK: - Button style

struct CancelViewScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Ambient radial-glow background

struct ExpertCancellationAmbientGlow: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(
                    colors: [ExpertCancellationBrand.brandGreen.opacity(0.15), .clear],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.8
                )
                RadialGradient(
                    colors: [ExpertCancellationBrand.brandGreen.opacity(0.05), .clear],
                    center: .init(x: 1.0, y: 0.5),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.6
                )
                RadialGradient(
                    colors: [ExpertCancellationBrand.brandGreen.opacity(0.08), .clear],
                    center: .init(x: 0.0, y: 1.0),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.6
                )
            }
        }
    }
}
