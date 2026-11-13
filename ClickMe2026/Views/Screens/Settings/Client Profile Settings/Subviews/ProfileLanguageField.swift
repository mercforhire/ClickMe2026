//
//  ProfileLanguageField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Spoken languages chips field (tappable)

struct ProfileLanguageField: View {
    let languages: [String]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ProfileSettingsBrand.fieldBg)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spoken Languages")
                        .font(.brand(.caption2, weight: .semibold))
                        .foregroundColor(ProfileSettingsBrand.labelColor)
                    if languages.isEmpty {
                        // A profile with no language yet (UI-SPEC EM4).
                        Text("Add languages")
                            .font(.brand(.subheadline, weight: .regular))
                            .foregroundColor(ProfileSettingsBrand.onSurfaceVar)
                    } else {
                        // Wraps: the catalog picker allows far more than the old 12 labels.
                        ProfileFlowLayout(spacing: 8) {
                            ForEach(Array(languages.enumerated()), id: \.offset) { _, lang in
                                Text(lang)
                                    .font(.brand(.caption, weight: .medium))
                                    .foregroundColor(ProfileSettingsBrand.onSurface)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(ProfileSettingsBrand.chipBg)
                                            .overlay(Capsule().stroke(ProfileSettingsBrand.chipBorder, lineWidth: 1))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(minHeight: 70)
        }
        .buttonStyle(.plain)
    }
}
