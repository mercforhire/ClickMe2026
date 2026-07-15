//
//  AllCategoriesBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens

enum AllCategoriesBrand {
    static let bg = Color(red: 0.055, green: 0.060, blue: 0.070)
    static let sheetBg = Color(red: 0.070, green: 0.075, blue: 0.090)
    static let cardBg = Color(red: 0.105, green: 0.115, blue: 0.130)
    static let fieldBg = Color(red: 0.090, green: 0.100, blue: 0.115)
    static let fieldBorder = Color(red: 0.220, green: 0.260, blue: 0.240)
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    static let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.600)
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)
}

// MARK: - Button style

struct CatCellScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.70), value: configuration.isPressed)
    }
}
