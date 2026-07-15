//
//  LoginHeaderSection.swift
//  ClickMe2026
//

import SwiftUI

struct LoginHeaderSection: View {
    var body: some View {
        VStack(spacing: 10) {
            ClickMeLogoMark(size: 80)

            Text("ClickMe")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Welcome back! Please enter your details.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
