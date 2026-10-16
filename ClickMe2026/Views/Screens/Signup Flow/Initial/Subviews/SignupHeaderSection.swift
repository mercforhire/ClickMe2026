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
                    .font(.brand(.title, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.brand(.title, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 6)
        }
    }
}
