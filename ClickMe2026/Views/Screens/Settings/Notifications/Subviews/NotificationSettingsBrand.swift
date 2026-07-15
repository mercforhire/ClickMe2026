//
//  NotificationSettingsBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — Luminous Dark

enum NotificationSettingsBrand {
    static let bg = Color(red: 0.055, green: 0.055, blue: 0.070) // near-black
    static let cardBg = Color(red: 0.095, green: 0.100, blue: 0.120) // dark glass fill
    static let rowBg = Color(red: 0.110, green: 0.115, blue: 0.135) // slightly lighter rows
    static let rowDivider = Color(red: 0.160, green: 0.165, blue: 0.190)
    static let brandGreen = Brand.primary // #44f697
    static let onSurface = Brand.onSurface // #e5e2e1
    static let onSurfaceVar = Color(red: 0.580, green: 0.630, blue: 0.610) // muted
    static let onPrimary = Brand.onPrimary // #003920

    /// Purple-blue iridescent border for outer card containers.
    static let iridBorder = LinearGradient(
        colors: [
            Color(red: 0.50, green: 0.38, blue: 0.90).opacity(0.70),
            Color(red: 0.35, green: 0.50, blue: 0.90).opacity(0.50),
            Color(red: 0.25, green: 0.75, blue: 0.65).opacity(0.40),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glass card background

struct NotificationGlassCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(NotificationSettingsBrand.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(NotificationSettingsBrand.iridBorder, lineWidth: 1.5)
            )
    }
}

// MARK: - Inner row group background

struct NotificationRowGroupBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(NotificationSettingsBrand.rowBg)
    }
}

// MARK: - Card title

struct NotificationCardTitle: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(NotificationSettingsBrand.onSurface)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}
