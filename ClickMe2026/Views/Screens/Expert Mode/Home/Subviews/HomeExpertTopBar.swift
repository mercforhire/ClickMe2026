//
//  HomeExpertTopBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Top app bar — ClickMe brand left, notification + avatar right

struct HomeExpertTopBar: View {
    var onNotifications: () -> Void = {}
    var onProfile: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ClickMeLogoMark(size: 28)
                Text("ClickMe")
                    .font(.system(size: 20, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundColor(Brand.onSurface)
            }

            Spacer()

            Button(action: onNotifications) {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Brand.onSurface)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Button(action: onProfile) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Brand.onSurfaceVariant, Brand.surfaceContainerLow)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            Brand.surfaceContainer
                .overlay(
                    Rectangle()
                        .fill(Brand.outlineVariant)
                        .frame(height: 1),
                    alignment: .bottom
                )
                .ignoresSafeArea(edges: .top)
        )
    }
}
