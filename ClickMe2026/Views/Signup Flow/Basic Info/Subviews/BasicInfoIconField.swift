//
//  BasicInfoIconField.swift
//  ClickMe2026
//

import SwiftUI

/// Rounded text field with a leading SF Symbol icon.
struct BasicInfoIconField: View {
    let systemImage: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(BasicInfoBrand.onSurfaceVar)
                .frame(width: 20)

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(BasicInfoBrand.onSurfaceVar)
                        .font(.system(size: 16, design: .rounded))
                }
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(BasicInfoBrand.onSurface)
                .tint(BasicInfoBrand.brandGreen)
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BasicInfoBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(BasicInfoBrand.fieldBorder, lineWidth: 1)
                )
        )
    }
}
