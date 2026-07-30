//
//  VerifyEmailMessageSection.swift
//  ClickMe2026
//

import SwiftUI

/// "Verify Your Email Address" headline, explainer copy, and the user's email
/// address rendered in a monospaced font. `didSend` flips the copy so we
/// don't imply an email was already sent on first entry — the send only
/// happens once the user taps the button below.
struct VerifyEmailMessageSection: View {
    let email: String
    var didSend: Bool = false

    private var explainer: String {
        didSend
            ? "We've sent a 6-digit code to your email address. Enter it below to verify."
            : "Tap the button below to send a 6-digit verification code to your email address."
    }

    var body: some View {
        VStack(spacing: 14) {
            Text("Verify Your Email Address")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(explainer)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.50))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text(email)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.70))
                .multilineTextAlignment(.center)
        }
    }
}
