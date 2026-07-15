//
//  CancellationPoliciesBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum CancellationPoliciesBrand {
    static let bg = Color(red: 0.065, green: 0.065, blue: 0.090)
    static let cardBg = Color(red: 0.095, green: 0.100, blue: 0.120)
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    static let onSurfaceVar = Color(red: 0.580, green: 0.630, blue: 0.610)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)
    static let errorRed = Color(red: 1.0, green: 0.42, blue: 0.42)

    // MARK: Iridescent card borders

    static let greenTealBorder = LinearGradient(
        colors: [Color(red: 0.22, green: 0.80, blue: 0.52).opacity(0.70),
                 Color(red: 0.18, green: 0.65, blue: 0.75).opacity(0.45)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let purpleTealBorder = LinearGradient(
        colors: [Color(red: 0.48, green: 0.36, blue: 0.88).opacity(0.65),
                 Color(red: 0.22, green: 0.72, blue: 0.78).opacity(0.40)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let blueGreenBorder = LinearGradient(
        colors: [Color(red: 0.28, green: 0.48, blue: 0.90).opacity(0.60),
                 Color(red: 0.20, green: 0.80, blue: 0.55).opacity(0.40)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Shared policy card shell

struct PolicyCard<Content: View>: View {
    let border: LinearGradient
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(CancellationPoliciesBrand.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(border, lineWidth: 1.5)
                    )
            )
    }
}

// MARK: - Card title

struct PolicyCardTitle: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(CancellationPoliciesBrand.onSurface)
    }
}
