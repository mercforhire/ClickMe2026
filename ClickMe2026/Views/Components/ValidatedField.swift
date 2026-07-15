//
//  ValidatedField.swift
//  ClickMe2026
//

import SwiftUI

/// Input row with a leading SF Symbol icon, red border on error, and an error
/// message below.
struct ValidatedField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    let error: String?

    var body: some View {
        let hasError = error != nil
        let borderColor = hasError ? Brand.destructive : Brand.outlineVariant
        let borderWidth: CGFloat = hasError ? 1.8 : 1.2

        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Brand.surfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .frame(height: 54)
                    .animation(.easeInOut(duration: 0.2), value: hasError)

                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(hasError ? Brand.destructive : Color.white.opacity(0.40))
                        .frame(width: 20)

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
                }
                .padding(.horizontal, 18)
            }

            if let msg = error {
                Text(msg)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Brand.destructive)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.2), value: error)
    }
}
