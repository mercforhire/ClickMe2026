//
//  VerifyEmailMessageSection.swift
//  ClickMe2026
//

import SwiftUI

/// "Verify Your Email Address" headline, explainer copy, and the user's email
/// address rendered in a monospaced font.
struct VerifyEmailMessageSection: View {
    let email: String

    var body: some View {
        VStack(spacing: 14) {
            Text("Verify Your Email Address")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("We've sent a verification link to your email address. Please check your inbox and click the link to continue.")
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
