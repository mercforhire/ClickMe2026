//
//  Brand.swift
//  ClickMe2026
//
//  App-wide design tokens (Luminous Dark palette per DESIGN.md).
//  This is the single source of truth for theme colors.
//

import SwiftUI

enum Brand {
    // MARK: - Surface layers

    nonisolated static let surface = Color(red: 0x13 / 255, green: 0x13 / 255, blue: 0x13 / 255) // #131313
    nonisolated static let surfaceContainerLowest = Color(red: 0x0e / 255, green: 0x0e / 255, blue: 0x0e / 255) // #0e0e0e
    nonisolated static let surfaceContainerLow = Color(red: 0x1c / 255, green: 0x1b / 255, blue: 0x1b / 255) // #1c1b1b
    nonisolated static let surfaceContainer = Color(red: 0x20 / 255, green: 0x1f / 255, blue: 0x1f / 255) // #201f1f
    nonisolated static let surfaceContainerHigh = Color(red: 0x2a / 255, green: 0x2a / 255, blue: 0x2a / 255) // #2a2a2a
    nonisolated static let surfaceContainerHighest = Color(red: 0x35 / 255, green: 0x35 / 255, blue: 0x34 / 255) // #353534

    // MARK: - Text / icons on surface

    nonisolated static let onSurface = Color(red: 0xe5 / 255, green: 0xe2 / 255, blue: 0xe1 / 255) // #e5e2e1
    nonisolated static let onSurfaceVariant = Color(red: 0xba / 255, green: 0xcb / 255, blue: 0xbc / 255) // #bacbbc
    nonisolated static let onSurfaceMuted = Color(white: 0.60) // mid-gray body text
    nonisolated static let onSurfaceFaint = Color(white: 0.43) // faint helper/label text

    // MARK: - Outlines

    nonisolated static let outline = Color(red: 0x85 / 255, green: 0x95 / 255, blue: 0x87 / 255) // #859587
    nonisolated static let outlineVariant = Color(red: 0x3c / 255, green: 0x4a / 255, blue: 0x3f / 255) // #3c4a3f

    // MARK: - Primary (neon green)

    nonisolated static let primary = Color(red: 0x44 / 255, green: 0xf6 / 255, blue: 0x97 / 255) // #44f697
    nonisolated static let primaryContainer = Color(red: 0x00 / 255, green: 0xd9 / 255, blue: 0x7e / 255) // #00d97e
    nonisolated static let onPrimary = Color(red: 0x00 / 255, green: 0x39 / 255, blue: 0x1d / 255) // #00391d
    nonisolated static let onPrimaryContainer = Color(red: 0x00 / 255, green: 0x59 / 255, blue: 0x30 / 255) // #005930

    // MARK: - Error

    nonisolated static let error = Color(red: 0xff / 255, green: 0xb4 / 255, blue: 0xab / 255) // #ffb4ab
    nonisolated static let onError = Color(red: 0x69 / 255, green: 0x00 / 255, blue: 0x05 / 255) // #690005
    /// Vivid destructive action red (buttons, "Decline" actions).
    nonisolated static let destructive = Color(red: 1.00, green: 0.30, blue: 0.30)

    // MARK: - Translucent white overlays

    nonisolated static let overlayWhite05 = Color.white.opacity(0.05)
    nonisolated static let overlayWhite06 = Color.white.opacity(0.06)
    nonisolated static let overlayWhite10 = Color.white.opacity(0.10)
    nonisolated static let overlayWhite15 = Color.white.opacity(0.15)
    nonisolated static let overlayWhite20 = Color.white.opacity(0.20)
    nonisolated static let overlayWhite22 = Color.white.opacity(0.22)
    nonisolated static let overlayWhite60 = Color.white.opacity(0.60)
    nonisolated static let overlayWhite80 = Color.white.opacity(0.80)

    // MARK: - Background aliases

    nonisolated static let background = surface
    nonisolated static let onBackground = onSurface
}
