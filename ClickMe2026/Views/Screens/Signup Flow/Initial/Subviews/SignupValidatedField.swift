//
//  SignupValidatedField.swift
//  ClickMe2026
//

import SwiftUI

/// Rounded text field with a red error state and an inline error message.
struct SignupValidatedField: View {
    let placeholder: String
    @Binding var text: String
    let error: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        let hasError = error != nil
        let border = hasError ? SignupBrand.errorRed : SignupBrand.fieldBorder
        let lineW: CGFloat = hasError ? 1.8 : 1.2

        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SignupBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(border, lineWidth: lineW)
                    )
                    .frame(height: 56)
                    .animation(.easeInOut(duration: 0.2), value: hasError)

                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                            .keyboardType(keyboardType)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(Color.white.opacity(0.30))
                        .font(.system(size: 16, design: .rounded))
                }
                .foregroundColor(.white)
                .font(.system(size: 16, design: .rounded))
                .padding(.horizontal, 18)
            }

            if let msg = error {
                Text(msg)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(SignupBrand.errorRed)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 14)
        .animation(.easeInOut(duration: 0.2), value: error)
    }
}
