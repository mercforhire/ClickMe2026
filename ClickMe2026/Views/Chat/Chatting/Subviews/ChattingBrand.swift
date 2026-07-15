//
//  ChattingBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum ChattingBrand {
    static let bg = Color(red: 0.055, green: 0.070, blue: 0.060) // #0e1210
    static let navBg = Color(red: 0.055, green: 0.070, blue: 0.060)
    static let myBubble = Color(red: 0.220, green: 0.878, blue: 0.482) // #38e07b
    static let theirBubble = Color(red: 0.110, green: 0.155, blue: 0.130)
    static let systemBg = Color(red: 0.120, green: 0.170, blue: 0.145)
    static let systemBorder = Color(red: 0.200, green: 0.280, blue: 0.230)
    static let inputBg = Color(red: 0.080, green: 0.115, blue: 0.095)
    static let inputBorder = Color(red: 0.200, green: 0.290, blue: 0.230)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592) // #44f697
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882) // #e5e2e1
    static let onSurfaceVar = Color(red: 0.550, green: 0.640, blue: 0.580)
    static let myText = Color(red: 0.000, green: 0.180, blue: 0.090) // dark on green
    static let senderLabel = Color(red: 0.500, green: 0.580, blue: 0.530)
}

// MARK: - Button scale style

struct ChatScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
