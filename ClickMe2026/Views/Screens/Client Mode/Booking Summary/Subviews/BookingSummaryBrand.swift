//
//  BookingSummaryBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum BookingSummaryBrand {
    static let bg = Brand.surface
    static let cardBg = Color(red: 0.125, green: 0.122, blue: 0.122)
    static let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    static let divider = Color(red: 0.212, green: 0.212, blue: 0.212)
    static let resourceBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    static let brandGreen = Brand.primary
    static let onSurface = Brand.onSurface
    static let onSurfaceVar = Brand.onSurfaceVariant
    static let onPrimary = Brand.onPrimary
    static let outlineVar = Brand.outlineVariant
}

// MARK: - Shared section header

struct BookingSummarySectionHeader: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(BookingSummaryBrand.brandGreen)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
                .tracking(1.2)
        }
    }
}

// MARK: - Glass card background

struct BookingSummaryGlassCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(BookingSummaryBrand.cardBg)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BookingSummaryBrand.cardBorder, lineWidth: 1))
    }
}
