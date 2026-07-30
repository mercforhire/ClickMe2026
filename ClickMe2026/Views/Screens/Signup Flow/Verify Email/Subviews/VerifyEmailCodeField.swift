//
//  VerifyEmailCodeField.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// 6-digit code entry field for the email verification step. Matches the
/// styling on the password-reset code field but uses the VerifyEmail
/// palette so the two flows read as separate.
struct VerifyEmailCodeField: View {
    @Binding var text: String
    let error: String?

    var body: some View {
        let hasError = error != nil
        let borderColor = hasError
            ? Color(red: 0.95, green: 0.35, blue: 0.35)
            : Color.white.opacity(0.15)
        let borderWidth: CGFloat = hasError ? 1.8 : 1.2

        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(VerifyEmailBrand.bubbleBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .frame(height: 56)
                    .animation(.easeInOut(duration: 0.2), value: hasError)

                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .placeholder(when: text.isEmpty) {
                        Text("Enter 6-digit code")
                            .foregroundColor(Color.white.opacity(0.28))
                            .font(.system(size: 16, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .kerning(6)
                    .padding(.horizontal, 16)
            }

            if let msg = error {
                Text(msg)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.55))
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: error)
    }
}
