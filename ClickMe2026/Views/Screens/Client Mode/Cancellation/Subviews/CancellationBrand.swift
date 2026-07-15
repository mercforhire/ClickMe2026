//
//  CancellationBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum CancellationBrand {
    static let bg = Color(red: 0.000, green: 0.000, blue: 0.000)
    static let cardBg = Brand.surface
    static let cardBorder = Color(red: 0.150, green: 0.165, blue: 0.155)
    static let innerBg = Color(red: 0.110, green: 0.110, blue: 0.110)
    static let innerBorder = Brand.outlineVariant
    static let fieldBg = Color(red: 0.110, green: 0.115, blue: 0.115)
    static let brandGreen = Brand.primary
    static let onSurface = Brand.onSurface
    static let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.600)
    static let onPrimary = Brand.onPrimary
    static let errorColor = Brand.error
    static let errorBorder = Brand.error.opacity(0.55)
    static let outlineVar = Brand.outlineVariant
    static let blobPurple = Color(red: 0.48, green: 0.23, blue: 0.93)
}

