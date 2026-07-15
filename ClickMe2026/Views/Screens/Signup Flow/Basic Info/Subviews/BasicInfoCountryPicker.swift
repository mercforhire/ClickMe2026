//
//  BasicInfoCountryPicker.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Country picker sized to sit alongside `BasicInfoTextField` in the
/// Province/State row. Binds to the ISO-3166-1 alpha-3 code the server
/// expects (`"USA"`, `"CAN"`, ...) and displays the localized country
/// name from `Countries.all`.
struct BasicInfoCountryPicker: View {
    @Binding var countryCode: String

    private var selectedName: String {
        Countries.find(byCode: countryCode)?.name
            ?? (countryCode.isEmpty ? "Country" : countryCode)
    }

    var body: some View {
        Menu {
            ForEach(Countries.all) { entry in
                Button {
                    countryCode = entry.code
                } label: {
                    HStack {
                        Text(entry.name)
                        if entry.code == countryCode {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedName)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(countryCode.isEmpty
                                     ? BasicInfoBrand.onSurfaceVar
                                     : BasicInfoBrand.onSurface)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BasicInfoBrand.onSurfaceVar)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BasicInfoBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BasicInfoBrand.fieldBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
