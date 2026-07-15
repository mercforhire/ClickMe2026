//
//  NewPasswordField.swift
//  ClickMe2026
//

import SwiftUI

/// Password input with an eye-toggle and a custom trailing badge slot.
struct NewPasswordField<Trailing: View>: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    let error: String?
    @ViewBuilder var trailingBadge: () -> Trailing

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

                HStack(spacing: 10) {
                    Group {
                        if isVisible {
                            TextField("", text: $text)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("", text: $text)
                        }
                    }
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Color.white.opacity(0.28))
                            .font(.system(size: 16, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .rounded))

                    Spacer()

                    HStack(spacing: 8) {
                        trailingBadge()

                        Button {
                            isVisible.toggle()
                        } label: {
                            Image(systemName: isVisible ? "eye" : "eye.slash")
                                .font(.system(size: 16))
                                .foregroundColor(Color.white.opacity(0.40))
                        }
                    }
                }
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
