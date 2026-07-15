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
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(Color.white.opacity(0.50))

            Button("Sign Up", action: onSignUp)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(LoginBrand.green)
        }
    }
}
