//
//  UpcomingBookingBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum UpcomingBookingBrand {
    static let bg = Brand.surface // #131313
    static let cardBg = Color(red: 0.125, green: 0.122, blue: 0.122) // #201f1f glass
    static let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173) // #2c2c2c
    static let divider = Color(red: 0.212, green: 0.212, blue: 0.212)
    static let attachBg = Color(red: 0.165, green: 0.165, blue: 0.170) // surface-container-high
    static let attachBorder = Color(red: 0.212, green: 0.212, blue: 0.212)
    static let videoBg = Color(red: 0.12, green: 0.17, blue: 0.38).opacity(0.25)
    static let brandGreen = Brand.primary // #44f697
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Brand.onSurfaceVariant // #bacbbc
    static let onPrimary = Brand.onPrimary // #003920
    static let errorColor = Brand.error // #ffb4ab
    static let blueAccent = Color(red: 0.36, green: 0.61, blue: 0.95)
    static let avatarFallback = Color(red: 0.10, green: 0.15, blue: 0.12)
}

// MARK: - Shared glass card background (14pt radius)

struct UpcomingBookingGlassCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(UpcomingBookingBrand.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(UpcomingBookingBrand.cardBorder, lineWidth: 1)
            )
    }
}
