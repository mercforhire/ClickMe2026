//
//  SignUpFooter.swift
//  ClickMe2026
//

import SwiftUI

struct SignUpFooter: View {
    var onSignUp: () -> Void = {}

    var body: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.brand(.subheadline))
                .foregroundColor(Color.white.opacity(0.50))

            Button("Sign Up", action: onSignUp)
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(LoginBrand.green)
        }
    }
}
