//
//  ClickMeMark.swift
//  ClickMe
//

import SwiftUI

struct ClickMeMark: View {
    var body: some View {
        Image("SplashLogo")
            .resizable()
            .scaledToFit()
            .shadow(color: ClickMeTheme.green.opacity(0.85), radius: 14)
            .shadow(color: ClickMeTheme.glow.opacity(0.35), radius: 30)
    }
}
