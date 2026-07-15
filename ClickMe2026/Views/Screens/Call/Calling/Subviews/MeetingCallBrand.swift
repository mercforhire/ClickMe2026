//
//  MeetingCallBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum MeetingCallBrand {
    static let bg = Brand.surface // #131313
    static let surfaceHigh = Brand.surfaceContainerHigh // #2a2a2a
    static let brandGreen = Brand.primary // #44f697
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Brand.onSurfaceVariant // #bacbbc
    static let endRed = Color(red: 0.929, green: 0.259, blue: 0.259) // #ED4242
    static let endRedDeep = Color(red: 0.75, green: 0.15, blue: 0.15)
    static let controlBg = Color(red: 0.133, green: 0.153, blue: 0.165) // dark glass
    static let activeControl = Brand.primary.opacity(0.20)
    static let controlGradientTop = Color(red: 0.20, green: 0.23, blue: 0.22)
    static let controlGradientBottom = Color(red: 0.13, green: 0.15, blue: 0.14)
    static let vignetteTop = Color(red: 0.11, green: 0.14, blue: 0.13)
    static let avatarFallback = Color(red: 0.14, green: 0.18, blue: 0.16)
}

// MARK: - Button style

struct CallControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.70), value: configuration.isPressed)
    }
}

// MARK: - Background vignette (top-radial)

struct MeetingCallBackground: View {
    var body: some View {
        RadialGradient(
            colors: [MeetingCallBrand.vignetteTop, MeetingCallBrand.bg],
            center: .top,
            startRadius: 0,
            endRadius: 600
        )
        .ignoresSafeArea()
    }
}
