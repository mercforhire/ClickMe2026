//
//  MakeABookingBrand.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum MakeABookingBrand {
    static let bg = Brand.surface // #131313
    static let surface = Color(red: 0.125, green: 0.125, blue: 0.125) // #201f1f
    static let surfaceHigh = Brand.surfaceContainerHigh // #2a2a2a
    static let outlineVar = Brand.outlineVariant // #3c4a3f
    static let brandGreen = Brand.primary // #44f697
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Brand.onSurfaceVariant // #bacbbc
    static let onPrimary = Brand.onPrimary // #003920
}

// MARK: - Shared section header

struct MakeABookingSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(MakeABookingBrand.onSurface)
    }
}
