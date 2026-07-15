//
//  NewPasswordCodeField.swift
//  ClickMe2026
//

import SwiftUI

/// 6-digit verification-code input styled to match the other password fields.
struct NewPasswordCodeField: View {
    let placeholder: String
    @Binding var text: String
    let error: String?

    var body: some View {
        let hasError = error != nil
        let border = hasError ? NewPasswordBrand.errorRed : NewPasswordBrand.fieldBorder
        let lineW: CGFloat = hasError ? 1.8 : 1.2

        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(NewPasswordBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(border, lineWidth: lineW)
                    )
                    .frame(height: 56)
                    .animation(.easeInOut(duration: 0.2), value: hasError)

                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Color.white.opacity(0.28))
                            .font(.system(size: 16, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .rounded))
                    .kerning(2)
                    .padding(.horizontal, 16)
            }

            if let msg = error {
                Text(msg)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(NewPasswordBrand.errorRed)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: error)
    }
}
