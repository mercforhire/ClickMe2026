//
//  ProfileModeSwitchCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Prominent call-to-action row at the top of `ClientProfileSettingsView`
/// that navigates to `ModeSwitchView`. Sized and coloured to draw attention
/// — this is the primary way clients discover the expert-side flow.
struct ProfileModeSwitchCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge

                VStack(alignment: .leading, spacing: 3) {
                    Text("Switch to Expert Mode")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(ProfileSettingsBrand.onSurface)
                    Text("Start offering consultations")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(ProfileSettingsBrand.onSurfaceVar)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ProfileSettingsBrand.brandGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ProfileSettingsBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(ProfileSettingsBrand.brandGreen.opacity(0.55), lineWidth: 1.2)
                    )
                    .shadow(color: ProfileSettingsBrand.brandGreen.opacity(0.20), radius: 12, x: 0, y: 3)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfileSettingsBrand.brandGreen.opacity(0.16))
                .frame(width: 44, height: 44)
            Image(systemName: "briefcase.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ProfileSettingsBrand.brandGreen)
        }
    }
}
