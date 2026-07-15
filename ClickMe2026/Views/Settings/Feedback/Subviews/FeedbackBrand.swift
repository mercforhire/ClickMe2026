//
//  FeedbackBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum FeedbackBrand {
    static let bg = Color(red: 0.075, green: 0.080, blue: 0.095)
    static let cardBg = Color(red: 0.095, green: 0.100, blue: 0.118)
    static let fieldBg = Color(red: 0.108, green: 0.125, blue: 0.140)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    static let outlineVar = Color(red: 0.235, green: 0.290, blue: 0.247)
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    static let onSurfaceVar = Color(red: 0.580, green: 0.630, blue: 0.600)
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)
    static let errorRed = Color(red: 1.000, green: 0.706, blue: 0.671)

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

// MARK: - Button style

struct FeedbackScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Field label

struct FeedbackFieldLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(FeedbackBrand.onSurfaceVar)
    }
}

// MARK: - Input field background

struct FeedbackInputFieldBackground: View {
    var hasError: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(FeedbackBrand.fieldBg)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        hasError ? FeedbackBrand.errorRed.opacity(0.70) : FeedbackBrand.brandGreen.opacity(0.45),
                        lineWidth: 1.2
                    )
                    .shadow(
                        color: hasError ? FeedbackBrand.errorRed.opacity(0.15) : FeedbackBrand.brandGreen.opacity(0.12),
                        radius: 4
                    )
            )
    }
}
