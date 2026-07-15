//
//  PressScaleButtonStyle.swift
//  ClickMe2026
//

import SwiftUI

/// Standard press-scale button style used across the app.
/// Scales down slightly on press for tactile feedback.
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
