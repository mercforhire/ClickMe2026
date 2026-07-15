//
//  BasicInfoTextField.swift
//  ClickMe2026
//

import SwiftUI

/// Rounded-rectangle plain text field used across the personal-details form.
struct BasicInfoTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(BasicInfoBrand.onSurfaceVar)
                    .font(.system(size: 16, design: .rounded))
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundColor(BasicInfoBrand.onSurface)
            .tint(BasicInfoBrand.brandGreen)
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
