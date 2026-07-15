//
//  ProfileLanguageField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
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
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(ProfileSettingsBrand.labelColor)
                    HStack(spacing: 8) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
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
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(minHeight: 70)
        }
        .buttonStyle(.plain)
    }
}
