//
//  SignupHeaderSection.swift
//  ClickMe2026
//

import SwiftUI

/// Logo + wordmark and a step title — reused across signup screens.
struct SignupHeaderSection: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ClickMeLogoMark(size: 56)
                Text("ClickMe")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 6)
        }
    }
}
