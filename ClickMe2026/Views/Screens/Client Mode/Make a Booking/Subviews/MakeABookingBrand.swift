//
//  MakeABookingBrand.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum MakeABookingBrand {
    static let bg = Color(red: 0.075, green: 0.075, blue: 0.075) // #131313
    static let surface = Color(red: 0.125, green: 0.125, blue: 0.125) // #201f1f
    static let surfaceHigh = Color(red: 0.165, green: 0.165, blue: 0.165) // #2a2a2a
    static let outlineVar = Color(red: 0.235, green: 0.290, blue: 0.247) // #3c4a3f
    static let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592) // #44f697
    static let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882) // #e5e2e1
    static let onSurfaceVar = Color(red: 0.729, green: 0.796, blue: 0.737) // #bacbbc
    static let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114) // #003920
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
