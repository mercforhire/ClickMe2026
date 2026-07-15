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
    static let brandGreen = Brand.primary
    static let outlineVar = Brand.outlineVariant
    static let onSurface = Brand.onSurface
    static let onSurfaceVar = Color(red: 0.580, green: 0.630, blue: 0.600)
    static let onPrimary = Brand.onPrimary
    static let errorRed = Brand.error

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
