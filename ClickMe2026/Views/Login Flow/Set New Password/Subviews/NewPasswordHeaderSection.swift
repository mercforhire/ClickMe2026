//
//  NewPasswordHeaderSection.swift
//  ClickMe2026
//

import SwiftUI

struct NewPasswordHeaderSection: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ClickMeLogoMark(size: 56)
                Text("ClickMe")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text("Set New Password")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 6)
        }
    }
}
