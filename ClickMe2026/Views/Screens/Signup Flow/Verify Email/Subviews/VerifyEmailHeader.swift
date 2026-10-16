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
                .font(.brand(.title, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
