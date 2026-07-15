//
//  VerifyEmailHeader.swift
//  ClickMe2026
//

import SwiftUI

struct VerifyEmailHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            ClickMeLogoMark(size: 56)
            Text("ClickMe")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
