//
//  ColorHexInit.swift
//  ClickMe2026
//

import SwiftUI

extension Color {
    /// Builds a color from a 24-bit RGB hex literal, e.g. `0x44F697`.
    init(hex: UInt) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255
        )
    }
}
