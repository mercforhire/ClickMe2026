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
            .shadow(color: Brand.primary.opacity(0.85), radius: 14)
            .shadow(color: Brand.primary.opacity(0.35), radius: 30)
    }
}
