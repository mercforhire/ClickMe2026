//
//  ProfileBioField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Multi-line bio field

struct ProfileBioField: View {
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfileSettingsBrand.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
                .frame(minHeight: 110)
            VStack(alignment: .leading, spacing: 3) {
                Text("Bio")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.labelColor)
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(ProfileSettingsBrand.onSurface)
                    .font(.system(size: 15, design: .rounded))
                    .tint(ProfileSettingsBrand.brandGreen)
                    .frame(minHeight: 80)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}
