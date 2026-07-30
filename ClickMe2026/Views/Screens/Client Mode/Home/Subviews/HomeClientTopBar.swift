//
//  HomeClientTopBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Top app bar — ClickMe brand left, notification + avatar right

struct HomeClientTopBar: View {
    /// User's avatar URL. When present, renders the actual image in the
    /// top-right; falls back to the silhouette when nil / empty. Wired
    /// by the shell from `UserManager.profile?.personalDetails.avatarUrl`.
    var avatarURL: String? = nil
    var onNotifications: () -> Void = {}
    /// Wired to push the ModeSwitchView so the top-bar avatar becomes
    /// a 1-tap mode-switch shortcut.
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

            TopBarAvatarButton(avatarURL: avatarURL, action: onProfile)
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
