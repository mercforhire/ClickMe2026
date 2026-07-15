//
//  ProfileCountryField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Country picker (bound to an ISO-3166-1 alpha-3 code)
//
// The binding always holds the alpha-3 code (`"USA"`, `"CAN"`, ...) so the
// server always receives a valid enum value. Display renders the localized
// country name from `Countries.all`.

struct ProfileCountryField: View {
    @Binding var country: String

    private var selectedName: String {
        Countries.find(byCode: country)?.name ?? (country.isEmpty ? "Select" : country)
    }

    var body: some View {
        Menu {
            ForEach(Countries.all) { entry in
                Button {
                    country = entry.code
                } label: {
                    HStack {
                        Text(entry.name)
                        if entry.code == country {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
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
                        Text(selectedName)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(country.isEmpty
                                             ? ProfileSettingsBrand.onSurfaceVar
                                             : ProfileSettingsBrand.onSurface)
                            .lineLimit(1)
                        Spacer()
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
        .buttonStyle(.plain)
    }
}
