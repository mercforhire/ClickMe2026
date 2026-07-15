//
//  ProfileCountryField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Country field with chevron

struct ProfileCountryField: View {
    @Binding var country: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfileSettingsBrand.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text("Country")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.labelColor)
                HStack {
                    TextField("", text: $country)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(ProfileSettingsBrand.onSurface)
                        .tint(ProfileSettingsBrand.brandGreen)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(ProfileSettingsBrand.onSurfaceVar)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 60)
        .frame(maxWidth: .infinity)
    }
}
