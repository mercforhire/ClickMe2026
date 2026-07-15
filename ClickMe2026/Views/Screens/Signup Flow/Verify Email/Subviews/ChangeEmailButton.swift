//
//  ChangeEmailButton.swift
//  ClickMe2026
//

import SwiftUI

/// Outlined brand-green pill that lets the user go back to change their email.
struct ChangeEmailButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(VerifyEmailBrand.green, lineWidth: 1.5)
                    )
                    .frame(height: 56)

                Text("Change Email Address")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VerifyEmailBrand.green)
            }
        }
        .frame(height: 56)
    }
}
