//
//  ResendEmailButton.swift
//  ClickMe2026
//

import SwiftUI

/// Filled brand-green pill that swaps between idle "Resend Email", spinner,
/// "Resend in Ns" cooldown, and post-send "Email Sent!" confirmation.
struct ResendEmailButton: View {
    let isResending: Bool
    let resendCooldown: Int
    let didResend: Bool
    let action: () -> Void

    private var isDisabled: Bool { isResending || resendCooldown > 0 }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(VerifyEmailBrand.green)
                    .shadow(color: VerifyEmailBrand.green.opacity(0.40), radius: 14, x: 0, y: 5)
                    .frame(height: 56)

                if isResending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if resendCooldown > 0 {
                    Text("Resend in \(resendCooldown)s")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                } else if didResend {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Email Sent!")
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                } else {
                    Text("Resend Email")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 56)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.70 : 1)
    }
}
