//
//  ChatConversationsBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum ChatConversationsBrand {
    static let bg = Color(red: 0.055, green: 0.070, blue: 0.060) // #0e1210 deep green-black
    static let cardBg = Color(red: 0.100, green: 0.120, blue: 0.108) // #1a1f1b
    static let cardBorder = Color(red: 0.180, green: 0.240, blue: 0.196)
    static let fieldBg = Color(red: 0.075, green: 0.105, blue: 0.082)
    static let fieldBorder = Color(red: 0.235, green: 0.310, blue: 0.247)
    static let brandGreen = Brand.primary // #44f697
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Color(red: 0.600, green: 0.680, blue: 0.622)
    static let onPrimary = Brand.onPrimary // #003920
    static let activePill = Color(red: 0.120, green: 0.200, blue: 0.145)
}

// MARK: - Chat row button style

struct ChatRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.10), value: configuration.isPressed)
    }
}
