//
//  RequestDecisionTheme.swift
//  ClickMe2026
//
//  Screen-specific overlay palette. Standard tokens live in Brand.
//  This screen uses translucent white overlays for a distinctive look.
//

import SwiftUI

enum RequestDecisionTheme {
    static let cardBg = Color.white.opacity(0.05)
    static let divider = Color.white.opacity(0.10)
    static let onSurfaceVar = Color.white.opacity(0.60)
    static let onSurfaceMid = Color.white.opacity(0.80)
    static let declineBg = Color.white.opacity(0.22)
    static let messageBg = Color.white.opacity(0.10)
    static let earningsBg = Brand.primary.opacity(0.20)

    // Bottom sheet
    static let sheetBg = Color(red: 0.11, green: 0.18, blue: 0.13)
    static let sheetInnerBg = Color.black.opacity(0.20)
    static let destructive = Color(red: 1.00, green: 0.30, blue: 0.30)
}
