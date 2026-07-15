//
//  ProfileAccountSettingsRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Account settings row

struct ProfileAccountSettingsRow: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(ProfileSettingsBrand.onSurface)
                Text("Account Settings")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.onSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ProfileSettingsBrand.onSurfaceVar)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ProfileSettingsBrand.settingsBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ProfileSettingsBrand.settingsBdr, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
